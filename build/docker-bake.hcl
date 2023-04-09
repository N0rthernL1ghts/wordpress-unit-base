group "default" {
  targets = ["1_0_0"]
}

target "build-dockerfile" {
  dockerfile = "Dockerfile"
}

target "build-platforms" {
  platforms = ["linux/amd64", "linux/armhf", "linux/aarch64"]
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
  params = [wp_img_base_version, php_version]
  result = {
    WP_IMG_BASE_VERSION = wp_img_base_version
    PHP_VERSION = php_version
  }
}

# Get the cache-from configuration
function "get-cache-from" {
  params = [version]
  result = [
    "type=gha,scope=${version}_${BAKE_LOCAL_PLATFORM}",
    "type=registry,ref=${REGISTRY_CACHE}:${sha1("${version}-${BAKE_LOCAL_PLATFORM}")}"
  ]
}

# Get the cache-to configuration
function "get-cache-to" {
  params = [version]
  result = [
    "type=gha,mode=max,scope=${version}_${BAKE_LOCAL_PLATFORM}",
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
      "docker.io/nlss/wordpress-unit-base:${version}"
    ],
    flatten([
      for extra_version in extra_versions : [
        "docker.io/nlss/wordpress-unit-base:${extra_version}"
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
  tags       = get-tags("1.0.0", ["1", "1.0", "latest"])
  args       = get-args("6.1.1", "8.1")
}