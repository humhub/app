# Shared helpers for the e2e scripts; source it, don't run it.
#
# E2E_BACKEND selects how the HumHub backend runs:
#   docker  docker-compose.yml (default; Android)
#   native  PHP + MariaDB on the host, see native/start.sh (iOS: the
#           simulator reaches the host's localhost, and GitHub's macOS
#           runners can't run Docker)

e2e_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_BACKEND="${E2E_BACKEND:-docker}"
e2e_native_humhub="$e2e_dir/native/.humhub"

# Written by up.sh. Per backend, as the device-facing base URL differs.
if [ "$E2E_BACKEND" = docker ]; then
  e2e_fixtures_file="$e2e_dir/.e2e_fixtures.env"
else
  e2e_fixtures_file="$e2e_dir/.e2e_fixtures.$E2E_BACKEND.env"
fi

e2e_yii() {
  case "$E2E_BACKEND" in
    docker) (cd "$e2e_dir" && docker compose exec -T humhub /app/yii "$@") ;;
    native) php "$e2e_native_humhub/protected/yii" "$@" ;;
    *)
      echo "Unknown E2E_BACKEND '$E2E_BACKEND' (docker or native)" >&2
      return 1
      ;;
  esac
}

# Fails unless the user uploaded a file with the given name.
e2e_assert_upload() {
  echo "Checking the shared file reached the backend..."
  e2e_yii e2e/seed/assert-upload "$1" "$2"
}
