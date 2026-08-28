cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "usb_detector_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "usb_detector_windows_plugin")

add_library(${PLUGIN_NAME} SHARED
  "usb_detector_windows_plugin.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
# 插件经 .plugin_symlinks 编译, CMAKE_CURRENT_SOURCE_DIR 为 symlink 形式:
# .../flutter/ephemeral/.plugin_symlinks/<plugin>/windows -> 上溯 3 级 = ephemeral
set(USB_EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../..")
if(NOT EXISTS "${USB_EPHEMERAL_DIR}/cpp_client_wrapper/include/flutter/plugin.h")
  message(WARNING "usb_detector: cpp_client_wrapper not found at ${USB_EPHEMERAL_DIR}; wrapper includes may fail")
endif()
# 显式继承 flutter_wrapper_plugin 的 include(传递在 symlink 插件上失效的兜底)
get_target_property(USB_WRAPPER_INCLUDES flutter_wrapper_plugin INTERFACE_INCLUDE_DIRECTORIES)
if(USB_WRAPPER_INCLUDES)
  target_include_directories(${PLUGIN_NAME} PRIVATE ${USB_WRAPPER_INCLUDES})
endif()
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${USB_EPHEMERAL_DIR}/include"
  "${USB_EPHEMERAL_DIR}/cpp_client_wrapper/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
target_link_libraries(${PLUGIN_NAME} PRIVATE "setupapi.lib")

set(usb_detector_windows_bundled_libraries
  ""
  PARENT_SCOPE
)
