#!/bin/sh
# This script attempts to automatically update the vendorHash in default.nix

set -e # Exit immediately if a command exits with a non-zero status.

DEFAULT_NIX="default.nix"
# Timestamp for unique backup name
TIMESTAMP=$(date +%s)
ORIGINAL_BACKUP_NIX="${DEFAULT_NIX}.bak.vendorupdate.${TIMESTAMP}"

# Temporary copy of default.nix used to trigger the nix-build hash calculation
TEMP_NIX_FOR_HASH_CHECK="${DEFAULT_NIX}.forhashcheck.tmp"
# Temporary file for sed output
SED_OUT_TEMP_FILE="${DEFAULT_NIX}.sed.tmp"

cleanup() {
    echo "Cleaning up temporary files: ${TEMP_NIX_FOR_HASH_CHECK}, ${SED_OUT_TEMP_FILE}"
    rm -f "${TEMP_NIX_FOR_HASH_CHECK}" >/dev/null 2>&1 || true
    rm -f "${SED_OUT_TEMP_FILE}" >/dev/null 2>&1 || true
}
# Register cleanup function to run on script exit (normal, error, or signal interruption)
trap cleanup EXIT HUP INT QUIT TERM

echo "Attempting to update vendorHash in ${DEFAULT_NIX}..."

# 1. Create a timestamped backup of the current default.nix
cp "${DEFAULT_NIX}" "${ORIGINAL_BACKUP_NIX}"
echo "Backed up original ${DEFAULT_NIX} to ${ORIGINAL_BACKUP_NIX}"

# 2. Create a temporary copy of default.nix to modify for the hash check
cp "${DEFAULT_NIX}" "${TEMP_NIX_FOR_HASH_CHECK}"

# 3. Temporarily set an incorrect hash in this temporary copy.
# The sed command here redirects its output to SED_OUT_TEMP_FILE, then mv replaces TEMP_NIX_FOR_HASH_CHECK
sed 's#^ *vendorHash = .*;$#  vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";#' "${TEMP_NIX_FOR_HASH_CHECK}" > "${SED_OUT_TEMP_FILE}"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to modify temporary nix file ${TEMP_NIX_FOR_HASH_CHECK} with placeholder hash."
    # Restore original default.nix as a precaution, though TEMP_NIX_FOR_HASH_CHECK was the target
    cp "${ORIGINAL_BACKUP_NIX}" "${DEFAULT_NIX}"
    echo "${DEFAULT_NIX} has been restored from ${ORIGINAL_BACKUP_NIX}."
    exit 1
fi
mv "${SED_OUT_TEMP_FILE}" "${TEMP_NIX_FOR_HASH_CHECK}"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to move sed output to ${TEMP_NIX_FOR_HASH_CHECK}."
    cp "${ORIGINAL_BACKUP_NIX}" "${DEFAULT_NIX}"
    echo "${DEFAULT_NIX} has been restored from ${ORIGINAL_BACKUP_NIX}."
    exit 1
fi
echo "Temporarily modified ${TEMP_NIX_FOR_HASH_CHECK} with a placeholder hash."

# 4. Run nix-build on the temporary, modified default.nix to get the correct hash.
echo "Running nix-build to determine the correct vendorHash..."
NIX_BUILD_RAW_OUTPUT=$(nix-build --no-out-link "${TEMP_NIX_FOR_HASH_CHECK}" 2>&1 || true)

# Extract the hash using awk. Use printf for both echo and awk part for safety.
NEW_HASH=$(printf "%s" "$NIX_BUILD_RAW_OUTPUT" | awk '/^ *got: *sha256-/ { printf "%s", $2; exit }')

if [ -n "$NEW_HASH" ]; then
    echo "Successfully determined new vendorHash: $NEW_HASH"

    echo "Attempting to update ${DEFAULT_NIX} with sed..."
    # Temporarily disable exit on error to capture sed's specific error and exit code
    set +e
    sed 's@^ *vendorHash = .*;$@  vendorHash = "'"$NEW_HASH"'";@' "${DEFAULT_NIX}" > "${SED_OUT_TEMP_FILE}"
    SED_EXIT_CODE=$?
    set -e # Re-enable exit on error

    if [ $SED_EXIT_CODE -eq 0 ]; then
        # sed command reported success (exit code 0)
        # Check if SED_OUT_TEMP_FILE was actually created and is not empty
        if [ -s "${SED_OUT_TEMP_FILE}" ]; then
            mv "${SED_OUT_TEMP_FILE}" "${DEFAULT_NIX}"
            MV_EXIT_CODE=$?

            if [ $MV_EXIT_CODE -eq 0 ]; then
                echo "${DEFAULT_NIX} has been updated successfully with the new vendorHash."
                # Remove the backup file as the update was successful
                if rm -f "${ORIGINAL_BACKUP_NIX}"; then
                    echo "Successfully removed backup file ${ORIGINAL_BACKUP_NIX}."
                else
                    echo "Warning: Failed to remove backup file ${ORIGINAL_BACKUP_NIX}. You may need to remove it manually."
                fi
            else
                echo "ERROR: mv command failed with exit code $MV_EXIT_CODE after sed reported success."
                echo "Restoring ${DEFAULT_NIX} from backup: ${ORIGINAL_BACKUP_NIX}"
                cp "${ORIGINAL_BACKUP_NIX}" "${DEFAULT_NIX}"
                echo "${DEFAULT_NIX} has been restored."
                exit 1 # Indicate failure
            fi
        else
            echo "ERROR: sed command exited 0, but output file ${SED_OUT_TEMP_FILE} is empty or missing."
            echo "This suggests sed did not perform the substitution as expected."
            echo "Restoring ${DEFAULT_NIX} from backup: ${ORIGINAL_BACKUP_NIX}"
            if [ -f "${ORIGINAL_BACKUP_NIX}" ]; then # Check if backup exists
                 cp "${ORIGINAL_BACKUP_NIX}" "${DEFAULT_NIX}"
                 echo "${DEFAULT_NIX} has been restored."
            else
                 echo "ERROR: Backup file ${ORIGINAL_BACKUP_NIX} not found. Cannot restore."
            fi
            exit 1 # Indicate failure
        fi
    else
        # sed command failed (non-zero exit code)
        echo "ERROR: sed command failed with exit code $SED_EXIT_CODE."
        echo "Restoring ${DEFAULT_NIX} from backup: ${ORIGINAL_BACKUP_NIX}"
        if [ -f "${ORIGINAL_BACKUP_NIX}" ]; then # Check if backup exists
             cp "${ORIGINAL_BACKUP_NIX}" "${DEFAULT_NIX}"
             echo "${DEFAULT_NIX} has been restored."
        else
             echo "ERROR: Backup file ${ORIGINAL_BACKUP_NIX} not found. Cannot restore."
        fi
        exit 1 # Indicate failure
    fi
else
    echo "ERROR: Failed to automatically determine the new vendorHash from nix-build output."
    echo "Nix build output was:"
    printf "%s\n" "$NIX_BUILD_RAW_OUTPUT" # Added newline for readability
    echo ""
    echo "Original backup ${ORIGINAL_BACKUP_NIX} was created but no changes were attempted on ${DEFAULT_NIX}."
    exit 1 # Indicate failure
fi
