#!/usr/bin/env bash

function info {
  echo "$(tput setaf 2)INFO: $1$(tput sgr0)"
}

function error {
  echo "$(tput setaf 1)ERROR: $1$(tput sgr0)"
}

function banner {
  echo ""
  echo "$(tput setaf 5)######## $1 #######$(tput sgr0)"
  echo ""
}

function ditto_or_exit {
  ditto "${1}" "${2}"
  if [ "$?" != 0 ]; then
    error "Could not copy:"
    error "  source: ${1}"
    error "  target: ${2}"
    if [ ! -e "${1}" ]; then
      error "The source file does not exist"
      error "Did a previous xcodebuild step fail?"
    fi
    error "Exiting 1"
    exit 1
  fi
}

banner "Preparing"

if [ "${XCPRETTY}" = "0" ]; then
  USE_XCPRETTY=
else
  USE_XCPRETTY=`which xcpretty | tr -d '\n'`
fi

if [ ! -z ${USE_XCPRETTY} ]; then
  XC_PIPE='xcpretty -c'
else
  XC_PIPE='cat'
fi

XC_TARGET="CalWebView-cal"
XC_PROJECT="ios-webview-test-app.xcodeproj"
XC_BUILD_DIR="${PWD}/build/app-cal"
XC_CONFIG=Debug

APP="${XC_TARGET}.app"
DSYM="${APP}.dSYM"

INSTALL_DIR="Products/app-cal"
INSTALLED_APP="${INSTALL_DIR}/${APP}"
INSTALLED_DSYM="${INSTALL_DIR}/${DSYM}"

rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

info "Prepared install directory ${INSTALL_DIR}"

BUILD_PRODUCTS_DIR="${XC_BUILD_DIR}/Build/Products/${XC_CONFIG}-iphonesimulator"
BUILD_PRODUCTS_APP="${BUILD_PRODUCTS_DIR}/${APP}"
BUILD_PRODUCTS_DSYM="${BUILD_PRODUCTS_DIR}/${DSYM}"

rm -rf "${BUILD_PRODUCTS_APP}"
rm -rf "${BUILD_PRODUCTS_DSYM}"

OBJECT_ROOT_DIR="${XC_BUILD_DIR}/Build/Intermediates/${XC_CONFIG}-iphonesimulator"

info "Prepared archive directory"

banner "Building ${APP}"

if [ -z "${CODE_SIGN_IDENTITY}" ]; then
  COMMAND_LINE_BUILD=1 xcrun xcodebuild \
    -SYMROOT="${XC_BUILD_DIR}" \
    OBJROOT="${OBJECT_ROOT_DIR}" \
    BUILT_PRODUCTS_DIR="${BUILD_PRODUCTS_DIR}" \
    TARGET_BUILD_DIR="${BUILD_PRODUCTS_DIR}" \
    DWARF_DSYM_FOLDER_PATH="${BUILD_PRODUCTS_DIR}" \
    -project "${XC_PROJECT}" \
    -target "${XC_TARGET}" \
    -configuration "${XC_CONFIG}" \
    -sdk iphonesimulator \
    ARCHS="i386 x86_64" \
    VALID_ARCHS="i386 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    build | $XC_PIPE
else
  COMMAND_LINE_BUILD=1 xcrun xcodebuild \
    CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
    -SYMROOT="${XC_BUILD_DIR}" \
    OBJROOT="${OBJECT_ROOT_DIR}" \
    BUILT_PRODUCTS_DIR="${BUILD_PRODUCTS_DIR}" \
    TARGET_BUILD_DIR="${BUILD_PRODUCTS_DIR}" \
    DWARF_DSYM_FOLDER_PATH="${BUILD_PRODUCTS_DIR}" \
    -project "${XC_PROJECT}" \
    -target "${XC_TARGET}" \
    -configuration "${XC_CONFIG}" \
    -sdk iphonesimulator \
    ARCHS="i386 x86_64" \
    VALID_ARCHS="i386 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    build | $XC_PIPE
fi

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE != 0 ]; then
  error "Building app failed."
  exit $EXIT_CODE
else
  info "Building app succeeded."
fi

banner "Installing"

ditto_or_exit "${BUILD_PRODUCTS_APP}" "${INSTALLED_APP}"
info "Installed ${INSTALLED_APP}"

ditto_or_exit "${BUILD_PRODUCTS_DSYM}" "${INSTALLED_DSYM}"
info "Installed ${INSTALLED_DSYM}"
info "Done!"

