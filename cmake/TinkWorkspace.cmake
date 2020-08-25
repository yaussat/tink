# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Download, unpack and setup Tink dependencies.
#
# Despite the looks, http_archive rules are not purely declarative, and order
# matters. All variables defined before a rule are visible when configuring the
# dependency it declares, and the targets provided by a dependency are visible
# (only) after it has been declared. Following dependencies may rely on targets
# defined by a previous one, for instance on gtest or absl.
#
# Some rules imported from dependencies require small fixes, which are specified
# after the relative http_archive rule. Please always document the intended
# purpose of such statements, and why they are necessary.
#
# In general, when adding a new dependency you should follow this structure:
#
# <set any configuration variable, if any>
# <http_archive for your dependency>
# <define or fix newly imported targets, if any>
#
# Many projects provide switches to disable tests or examples, which you should
# specify, in order to speed up the compilation process.

include(HttpArchive)
include(TinkUtil)

set(gtest_force_shared_crt ON CACHE BOOL "Tink dependency override" FORCE)

http_archive(
  NAME com_google_googletest
  URL https://github.com/google/googletest/archive/eb9225ce361affe561592e0912320b9db84985d0.zip
  SHA256 a7db7d1295ce46b93f3d1a90dbbc55a48409c00d19684fcd87823037add88118
)

http_archive(
  NAME com_google_absl
  URL https://github.com/abseil/abseil-cpp/archive/db5773a721a50d1fc8c9b51efea0e70be4003d36.zip
  SHA256 83be4b9b919c3fe7574e49782ab924d5ac59f266f1e93c4e5fddf8a5fca43361
)

http_archive(
  NAME wycheproof
  URL https://github.com/google/wycheproof/archive/f89f4c53a8845fcefcdb9f14ee9191dbe167e3e3.zip
  SHA256 b44bb0339ad149e6cdab1337445cf52440cbfc79684203a3db1c094d9ef8daea
  DATA_ONLY
)

# Symlink the Wycheproof test data.
# Paths are hard-coded in tests, which expects wycheproof/ in this location.
add_directory_alias("${wycheproof_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/cc/wycheproof")

http_archive(
  NAME boringssl
  URL https://github.com/google/boringssl/archive/597b810379e126ae05d32c1d94b1a9464385acd0.zip
  SHA256 c4e8414cb36e62d2fee451296cc864f7ad1a4670396c8a67e1ee77ae84cc4167
  CMAKE_SUBDIR src
)

# BoringSSL targets do not carry include directory info, this fixes it.
target_include_directories(crypto PUBLIC "${boringssl_SOURCE_DIR}/src/include")

set(RAPIDJSON_BUILD_DOC OFF CACHE BOOL "Tink dependency override" FORCE)
set(RAPIDJSON_BUILD_EXAMPLES OFF CACHE BOOL "Tink dependency override" FORCE)
set(RAPIDJSON_BUILD_TESTS OFF CACHE BOOL "Tink dependency override" FORCE)

http_archive(
  NAME rapidjson
  URL https://github.com/Tencent/rapidjson/archive/v1.1.0.tar.gz
  SHA256 bf7ced29704a1e696fbccf2a2b4ea068e7774fa37f6d7dd4039d0787f8bed98e
)

# Rapidjson is a header-only library with no explicit target. Here we create one.
add_library(rapidjson INTERFACE)
target_include_directories(rapidjson INTERFACE "${rapidjson_SOURCE_DIR}")

set(protobuf_BUILD_TESTS OFF CACHE BOOL "Tink dependency override" FORCE)
set(protobuf_BUILD_EXAMPLES OFF CACHE BOOL "Tink dependency override" FORCE)

http_archive(
  NAME com_google_protobuf
  URL https://github.com/google/protobuf/archive/v3.11.4.zip
  SHA256 9748c0d90e54ea09e5e75fb7fac16edce15d2028d4356f32211cfa3c0e956564
  CMAKE_SUBDIR cmake
)

# Build aws-sdk::core and aws-sdk::kms
set(AWS_SDK_VERSION 1.8.24)
set(AWS_MAKE_CMD "${CMAKE_CURRENT_SOURCE_DIR}/cmake/build-aws-modules.sh")
message(STATUS "Downloading and building aws-sdk-cpp-${AWS_SDK_VERSION}")
execute_process(COMMAND ${AWS_MAKE_CMD} ${CMAKE_BINARY_DIR} ${AWS_SDK_VERSION})
set(AWS_SRC_DIR "${CMAKE_BINARY_DIR}/aws-sdk-cpp-${AWS_SDK_VERSION}")
add_library(aws-sdk::core STATIC IMPORTED)
add_library(aws-sdk::kms  STATIC IMPORTED)
set_target_properties(aws-sdk::core PROPERTIES IMPORTED_LOCATION ${AWS_SRC_DIR}/build/aws-cpp-sdk-core/libaws-cpp-sdk-core.a)
set_target_properties(aws-sdk::kms  PROPERTIES IMPORTED_LOCATION ${AWS_SRC_DIR}/build/aws-cpp-sdk-kms/libaws-cpp-sdk-kms.a)
set(AWS_INCLUDE_DIRS ${AWS_SRC_DIR}/aws-cpp-sdk-kms/include ${AWS_SRC_DIR}/aws-cpp-sdk-core/include)
list(APPEND TINK_INCLUDE_DIRS "${AWS_INCLUDE_DIRS}")
