cmake_minimum_required(VERSION 3.31)
project(test-systemd-units)
find_package(PkgConfig REQUIRED)
pkg_check_modules(SYSTEMD REQUIRED systemd)
pkg_get_variable(_SYSTEMD_PREFIX systemd prefix)
pkg_get_variable(_SYSTEMD_SYSTEMUNITDIR systemd systemdsystemunitdir)
pkg_get_variable(_SYSTEMD_USERUNITDIR systemd systemduserunitdir)

# TODO: automate this at the nixpkgs level
# NOTE: udev.pc doesn't even have a prefix
# NOTE: systemd seems to want to get rid of this 
string(REPLACE "${_SYSTEMD_PREFIX}/" "" __SYSTEMD_SYSTEMUNITDIR ${_SYSTEMD_SYSTEMUNITDIR})
string(REPLACE "${_SYSTEMD_PREFIX}/" "" __SYSTEMD_USERUNITDIR ${_SYSTEMD_USERUNITDIR})


add_executable(test-systemd-units test-systemd-units.c)
install(TARGETS test-systemd-units)
install(FILES test-systemd-units.service DESTINATION ${__SYSTEMD_SYSTEMUNITDIR})
