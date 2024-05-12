group "default" {
  targets = ["1_0_0", "1_0_0_PHP7_4", "1_1_0", "1_1_0_PHP7_4"]
}

target "build-dockerfile" {
  dockerfile = "Dockerfile"
}

target "build-platforms" {
  platforms = ["linux/amd64", "linux/aarch64"]
}

target "build-common" {
  pull = true
}

variable "REGISTRY_CACHE" {
  default = "docker.io/nlss/wordpress-unit-base-cache"
}

######################
# Define the functions
######################

# Get the arguments for the build
function "get-args" {
  params = [wp_img_base_version, php_version, unit_version]
  result = {
    WP_IMG_BASE_VERSION = wp_img_base_version
    PHP_VERSION = php_version
    UNIT_VERSION = notequal(unit_version, "") ? unit_version : "1.30.0"
  }
}

# Get the cache-from configuration
function "get-cache-from" {
  params = [version]
  result = [
    "type=registry,ref=${REGISTRY_CACHE}:${sha1("${version}-${BAKE_LOCAL_PLATFORM}")}"
  ]
}

# Get the cache-to configuration
function "get-cache-to" {
  params = [version]
  result = [
    "type=registry,mode=max,ref=${REGISTRY_CACHE}:${sha1("${version}-${BAKE_LOCAL_PLATFORM}")}"
  ]
}

# Get list of image tags and registries
# Takes a version and a list of extra versions to tag
# eg. get-tags("1_0_0", ["1.0", "latest"])
function "get-tags" {
  params = [version, extra_versions]
  result = concat(
    [
      "docker.io/nlss/wordpress-unit-base:${version}",
      "ghcr.io/n0rthernl1ghts/wordpress-unit-base:${version}"
    ],
    flatten([
      for extra_version in extra_versions : [
        "docker.io/nlss/wordpress-unit-base:${extra_version}",
        "ghcr.io/n0rthernl1ghts/wordpress-unit-base:${extra_version}"
      ]
    ])
  )
}

##########################
# Define the build targets
##########################

target "1_0_0" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("1.0.0")
  cache-to   = get-cache-to("1.0.0")
  tags       = get-tags("1.0.0", ["1.0"])
  args       = get-args("6.1.1", "8.1", "1.29.0")
}

target "1_0_0_PHP7_4" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("1.0.0-PHP7.4")
  cache-to   = get-cache-to("1.0.0-PHP7.4")
  tags       = get-tags("1.0.0-PHP7.4", ["1.0-PHP7.4"])
  args       = get-args("6.1.1", "7.4", "1.29.0")
}

target "1_1_0" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("1.1.0")
  cache-to   = get-cache-to("1.1.0")
  tags       = get-tags("1.1.0", ["1.1", "latest"])
  args       = get-args("6.1.1", "8.1", "1.30.0")
}

target "1_1_0_PHP7_4" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("1.1.0-PHP7.4")
  cache-to   = get-cache-to("1.1.0-PHP7.4")
  tags       = get-tags("1.1.0-PHP7.4", ["PHP7.4", "1.1-PHP7.4", "latest-PHP7.4"])
  args       = get-args("6.1.1", "7.4", "1.30.0")
}