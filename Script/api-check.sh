#!/bin/bash

# make this script executable from terminal:
# chmod u+x api-check.sh

set -e

IOS_TRIPLE="arm64-apple-ios12.0"
TVOS_TRIPLE="arm64-apple-tvos12.0"

parse_modules_from_package() {
    if [ ! -f "Package.swift" ]; then
        echo "Package.swift not found."
        exit 1
    fi
    swift package dump-package | jq -r '.products[] | select(.type | has("library")) | .name'
}

build_and_dump() {
    local module=$1
    local platform=$2
    local output_file=$3

    case "$platform" in
        ios) TRIPLE=$IOS_TRIPLE; SDK=iphoneos ;;
        tvos) TRIPLE=$TVOS_TRIPLE; SDK=appletvos ;;
        *) echo "Unsupported platform: $platform"; exit 1 ;;
    esac

    SDK_PATH=$(xcrun --sdk $SDK --show-sdk-path)
    
    if ! swift build --sdk "$SDK_PATH" --triple "$TRIPLE" > /dev/null 2>&1; then
        echo "Build failed."
        exit 1
    fi
        
    swift api-digester -sdk "$SDK_PATH" -dump-sdk -abi -module "$module" \
        -target "$TRIPLE" -swift-version 5 -o "$output_file" -I .build/debug/Modules \
        -avoid-location -avoid-tool-args  -abort-on-module-fail
}

run_api_digester() {
    local mode="$1"
    local flag
    if [[ "$mode" == "abi" ]]; then
        flag="--$1"
    else
        flag=""
    fi

    local output_file=$(mktemp)

    swift api-digester -sdk "$SDK_PATH" -target "$TRIPLE" -swift-version 5 -diagnose-sdk -print-module \
        $flag --input-paths "$api_file" --input-paths "$sdk_file" -o "$output_file"
    
    local output=$(sed '/^\s*$/d; /^\/\*/d' "$output_file")
    if [[ -n "$output" ]]; then
        echo "Error in [$module][$platform]: $mode differences found"
        echo "$output"
        exit 1    
    fi
}


check_api_diff() {
    local module=$1
    local platform=$2
    local sdk_file=$3
    local api_file=$4

    case "$platform" in
        ios) SDK=iphoneos ;;
        tvos) SDK=appletvos ;;
        *) echo "Unsupported platform: $platform"; exit 1 ;;
    esac

    SDK_PATH=$(xcrun --sdk "$SDK" --show-sdk-path)
    # Check for ABI differences
    run_api_digester "abi"

    # Check for API differences
    run_api_digester "api"


    # Check for file content differences
    if ! diff_output=$(diff "$api_file" "$sdk_file" 2>&1); then
        echo "Error in [$module][$platform]: API.json file changed"
        echo "$diff_output"
        exit 1
    fi

    echo "[$module][$platform]: No API changes" 
}

# Process input arguments
ACTION=""
MODULE=""
PLATFORM=""
while [ "$1" != "" ]; do
    case $1 in
        --check) ACTION="check" ;;
        --dump) ACTION="dump" ;;
        --module)
            shift
            MODULE=$1
            if [ -z "$MODULE" ]; then
                echo "Error: No module specified with --module."
                exit 1
            fi
            ;;
        --platform)
            shift
            PLATFORM=$1
            if [[ "$PLATFORM" != "ios" && "$PLATFORM" != "tvos" ]]; then
                echo "Error: Invalid platform specified. Use ios or tvos."
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [--check | --dump] [--module <module_name>] [--platform <ios|tvos>]"
            echo "Note: If --module is not specified, the script will run for all modules."
            exit 1
            ;;
    esac
    shift
done

# Function to run actions for a specific module
run_for_module() {
    local module=$1
    temp_file=".build/$module-$PLATFORM.json"
    api_file="api/$module-$PLATFORM.json"

    if [ "$ACTION" == "check" ]; then
        build_and_dump $module $PLATFORM $temp_file
        check_api_diff $module $PLATFORM $temp_file $api_file
    elif [ "$ACTION" == "dump" ]; then
        build_and_dump $module $PLATFORM $api_file
    fi
}

# Function to run actions for all modules
run_for_all_modules() {
    modules=$(parse_modules_from_package)
    for module in $modules; do
        run_for_module $module
    done
}

# Execute based on parsed parameters
if [ -z "$ACTION" ]; then
    echo "Error: No action specified. Use --check or --dump."
    exit 1
fi

if [ -z "$PLATFORM" ]; then
    echo "Error: No platform specified. Use --platform ios or --platform tvos."
    exit 1
fi

if [ -n "$MODULE" ]; then
    run_for_module $MODULE
else
    run_for_all_modules
fi

