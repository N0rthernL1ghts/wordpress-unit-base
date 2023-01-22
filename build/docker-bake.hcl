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

target "1_0_0" {
  inherits = ["build-dockerfile", "build-platforms", "build-common"]
  tags     = ["docker.io/nlss/wordpress-unit-base:latest", "docker.io/nlss/wordpress-unit-base:1.0.0"]
  args = {
    WP_IMG_BASE_VERSION = "6.1.1"
    PHP_VERSION = "8.1"
  }
}