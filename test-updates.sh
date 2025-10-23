#!/bin/bash
# Test all update.sh scripts locally

set -euo pipefail

echo "Testing all update scripts..."
echo "=============================="
echo ""

FAILED=()
UPDATED=()
SKIPPED=()

for script in */update.sh; do
    if [ ! -f "$script" ]; then
        continue
    fi
    
    package=$(dirname "$script")
    echo "Testing: $package"
    echo "---"
    
    cd "$package"
    
    if bash update.sh; then
        if git diff --quiet HEAD -- *.spec; then
            echo "✓ No updates needed"
            SKIPPED+=("$package")
        else
            echo "✓ Updated successfully"
            UPDATED+=("$package")
        fi
    else
        echo "✗ Failed"
        FAILED+=("$package")
    fi
    
    cd - > /dev/null
    echo ""
done

echo "=============================="
echo "Summary:"
echo ""

if [ ${#UPDATED[@]} -gt 0 ]; then
    echo "Updated packages:"
    printf '  - %s\n' "${UPDATED[@]}"
    echo ""
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo "Already up-to-date:"
    printf '  - %s\n' "${SKIPPED[@]}"
    echo ""
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    echo "Failed:"
    printf '  - %s\n' "${FAILED[@]}"
    exit 1
fi

echo "All checks passed!"
