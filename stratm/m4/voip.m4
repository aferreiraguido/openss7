# vim: ft=config sw=4 noet nocin nosi com=b\:#,b\:dnl,b\:***,b\:@%\:@ fo+=tcqlorn
# =============================================================================
# BEGINNING OF SEPARATE COPYRIGHT MATERIAL
# =============================================================================
# 
# @(#) $RCSfile: voip.m4,v $ $Name: OpenSS7-0_9_2 $($Revision: 0.9.2.22 $) $Date: 2008-10-30 11:36:16 $
#
# -----------------------------------------------------------------------------
#
# Copyright (c) 2001-2008  OpenSS7 Corporation <http://www.openss7.com/>
# Copyright (c) 1997-2001  Brian F. G. Bidulock <bidulock@openss7.org>
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation; version 3 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>, or write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# -----------------------------------------------------------------------------
#
# U.S. GOVERNMENT RESTRICTED RIGHTS.  If you are licensing this Software on
# behalf of the U.S. Government ("Government"), the following provisions apply
# to you.  If the Software is supplied by the Department of Defense ("DoD"), it
# is classified as "Commercial Computer Software" under paragraph 252.227-7014
# of the DoD Supplement to the Federal Acquisition Regulations ("DFARS") (or any
# successor regulations) and the Government is acquiring only the license rights
# granted herein (the license rights customarily provided to non-Government
# users).  If the Software is supplied to any unit or agency of the Government
# other than DoD, it is classified as "Restricted Computer Software" and the
# Government's rights in the Software are defined in paragraph 52.227-19 of the
# Federal Acquisition Regulations ("FAR") (or any successor regulations) or, in
# the cases of NASA, in paragraph 18.52.227-86 of the NASA Supplement to the FAR
# (or any successor regulations).
#
# -----------------------------------------------------------------------------
#
# Commercial licensing and support of this software is available from OpenSS7
# Corporation at a fee.  See http://www.openss7.com/
#
# -----------------------------------------------------------------------------
#
# Last Modified $Date: 2008-10-30 11:36:16 $ by $Author: brian $
#
# =============================================================================

# -----------------------------------------------------------------------------
# This file provides some common macros for finding a STREAMS VOIP
# release and necessary include directories and other configuration for
# compiling kernel modules to run with the STREAMS VOIP package.
# -----------------------------------------------------------------------------
# Interesting enough, there is no need to have strvoip loaded on the build
# machine to compile modules.  Only the proper header files are required.
# -----------------------------------------------------------------------------

# =============================================================================
# _VOIP
# -----------------------------------------------------------------------------
# Check for the existence of VOIP header files, particularly voip/sys/h225.h.
# VOIP header files are required for building the VOIP interface.
# Without VOIP header files, the VOIP interface will not be built.
# -----------------------------------------------------------------------------
AC_DEFUN([_VOIP], [dnl
    _VOIP_CHECK
    if test :"${voip_cv_includes:-no}" = :no ; then
	AC_MSG_ERROR([
*** 
*** Configure could not find the STREAMS VOIP include directories.  If
*** you wish to use the STREAMS VOIP package you will need to specify
*** the location of the STREAMS VOIP (strvoip) include directories with
*** the --with-voip=@<:@DIRECTORY@:>@ option to ./configure and try again.
***
*** Perhaps you just forgot to load the STREAMS VOIP package?  The
*** STREAMS strvoip package is available from The OpenSS7 Project
*** download page at http://www.openss7.org/ and comes in a tarball
*** named something like "strvoip-0.9.2.4.tar.gz".
*** ])
    fi
])# _VOIP
# =============================================================================

# =============================================================================
# _VOIP_CHECK
# -----------------------------------------------------------------------------
AC_DEFUN([_VOIP_CHECK], [dnl
    AC_REQUIRE([_LINUX_STREAMS])dnl
    _VOIP_OPTIONS
    _VOIP_SETUP
dnl
dnl Skip kernel checks if not configuring for the kernel (i.e. no _LINUX_KERNEL)
dnl as we do for netperf.
dnl
    m4_ifdef([_LINUX_KERNEL], [_VOIP_KERNEL])
    _VOIP_USER
    _VOIP_OUTPUT
    AC_SUBST([VOIP_CPPFLAGS])dnl
    AC_SUBST([VOIP_MODFLAGS])dnl
    AC_SUBST([VOIP_LDADD])dnl
    AC_SUBST([VOIP_LDADD32])dnl
    AC_SUBST([VOIP_LDFLAGS])dnl
    AC_SUBST([VOIP_LDFLAGS32])dnl
    AC_SUBST([VOIP_MODMAP])dnl
    AC_SUBST([VOIP_SYMVER])dnl
    AC_SUBST([VOIP_MANPATH])dnl
    AC_SUBST([VOIP_VERSION])dnl
])# _VOIP_CHECK
# =============================================================================

# =============================================================================
# _VOIP_OPTIONS
# -----------------------------------------------------------------------------
# allow the user to specify the header file location
# -----------------------------------------------------------------------------
AC_DEFUN([_VOIP_OPTIONS], [dnl
    AC_ARG_WITH([voip],
	AS_HELP_STRING([--with-voip=HEADERS],
	    [specify the VOIP header file directory.  @<:@default=INCLUDEDIR/strvoip@:>@]),
	[with_voip="$withval" ; for s in ${!voip_cv_*} ; do eval "unset $s" ; done],
	[with_voip=''])
])# _VOIP_OPTIONS
# =============================================================================

# =============================================================================
# _VOIP_SETUP
# -----------------------------------------------------------------------------
AC_DEFUN([_VOIP_SETUP], [dnl
    _VOIP_CHECK_HEADERS
    for voip_include in $voip_cv_includes ; do
	VOIP_CPPFLAGS="${VOIP_CPPFLAGS}${VOIP_CPPFLAGS:+ }-I${voip_include}"
    done
    if test :"${voip_cv_config:-no}" != :no ; then
	VOIP_CPPFLAGS="${VOIP_CPPFLAGS}${VOIP_CPPFLAGS:+ }-include ${voip_cv_config}"
    fi
    if test :"${voip_cv_modversions:-no}" != :no ; then
	VOIP_MODFLAGS="${VOIP_MODFLAGS}${VOIP_MODFLAGS:+ }-include ${voip_cv_modversions}"
    fi
])# _VOIP_SETUP
# =============================================================================

# =============================================================================
# _VOIP_CHECK_HEADERS
# -----------------------------------------------------------------------------
AC_DEFUN([_VOIP_CHECK_HEADERS], [dnl
    # Test for the existence of Linux Fast-STREAMS VOIP header files.  The
    # package normally requires VOIP header files to compile.
    AC_CACHE_CHECK([for voip include directory], [voip_cv_includes], [dnl
	voip_what="sys/h225.h"
	if test :"${with_voip:-no}" != :no -a :"${with_voip:-no}" != :yes ; then
	    # First thing to do is to take user specified director(ies)
	    AC_MSG_RESULT([(searching $with_voip)])
	    for voip_dir in $with_voip ; do
		if test -d "$voip_dir" ; then
		    AC_MSG_CHECKING([for voip include directory... $voip_dir])
		    if test -r "$voip_dir/$voip_what" ; then
			voip_cv_includes="$with_voip"
			AC_MSG_RESULT([yes])
			break
		    fi
		    AC_MSG_RESULT([no])
		fi
	    done
	    if test :"${voip_cv_includes:-no}" = :no ; then
		AC_MSG_WARN([
***
*** You have specified include directories using:
***
***	    --with-voip="$with_voip"
***
*** however, $voip_what does not exist in any of the specified
*** directories.  Configure will continue to search other known
*** directories.
*** ])
	    fi
	    AC_MSG_CHECKING([for voip include directory])
	fi
	if test :"${voip_cv_includes:-no}" = :no ; then
	    # The next place to look is under the master source and build
	    # directory, if any.
	    AC_MSG_RESULT([(searching $os7_cv_master_srcdir $os7_cv_master_builddir)])
	    voip_bld="${os7_cv_master_builddir:+$os7_cv_master_builddir/strvoip/src/include}"
	    voip_inc="${os7_cv_master_builddir:+$os7_cv_master_builddir/strvoip/include}"
	    voip_dir="${os7_cv_master_srcdir:+$os7_cv_master_srcdir/strvoip/src/include}"
	    if test -d "$voip_dir" ; then
		AC_MSG_CHECKING([for voip include directory... $voip_dir $voip_bld])
		if test -r "$voip_dir/$voip_what" ; then
		    voip_cv_includes="$voip_inc $voip_bld $voip_dir"
		    voip_cv_ldadd= # "$os7_cv_master_builddir/strvoip/libvoip.la"
		    voip_cv_ldadd32= # "$os7_cv_master_builddir/strvoip/lib32/libvoip.la"
		    voip_cv_modversions="$os7_cv_master_builddir/strvoip/include/sys/strvoip/modversions.h"
		    voip_cv_modmap="$os7_cv_master_builddir/strvoip/Modules.map"
		    voip_cv_symver="$os7_cv_master_builddir/strvoip/Module.symvers"
		    voip_cv_manpath="$os7_cv_master_builddir/strvoip/doc/man"
		    AC_MSG_RESULT([yes])
		else
		    AC_MSG_RESULT([no])
		fi
	    fi
	    AC_MSG_CHECKING([for voip include directory])
	fi
	if test :"${voip_cv_includes:-no}" = :no ; then
	    # The next place to look now is for a peer package being built under
	    # the same top directory, and then the higher level directory.
	    voip_here=`pwd`
	    AC_MSG_RESULT([(searching from $voip_here)])
	    for voip_dir in \
		$srcdir/strvoip*/src/include \
		$srcdir/../strvoip*/src/include \
		../_build/$srcdir/../../strvoip*/src/include \
		../_build/$srcdir/../../../strvoip*/src/include
	    do
		if test -d "$voip_dir" ; then
		    voip_bld=`echo $voip_dir | sed -e "s|^$srcdir/|$voip_here/|;"'s|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
		    voip_inc=`echo $voip_bld/../../include |sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
		    voip_dir=`(cd $voip_dir; pwd)`
		    AC_MSG_CHECKING([for voip include directory... $voip_dir $voip_bld])
		    if test -d "$voip_bld" -a -r "$voip_dir/$voip_what" ; then
			voip_cv_includes="$voip_inc $voip_bld $voip_dir"
			voip_cv_ldadd= # `echo "$voip_bld/../../libvoip.la" |sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
			voip_cv_ldadd32= # `echo "$voip_bld/../../lib32/libvoip.la" |sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
			voip_cv_modversions=`echo "$voip_inc/sys/strvoip/modversions.h" | sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
			voip_cv_modmap=`echo "$voip_bld/../../Modules.map" |sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
			voip_cv_symver=`echo "$voip_bld/../../Module.symvers" |sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
			voip_cv_manpath=`echo "$voip_bld/../../doc/man" |sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
			AC_MSG_RESULT([yes])
			break
		    fi
		    AC_MSG_RESULT([no])
		fi
	    done
	    AC_MSG_CHECKING([for voip include directory])
	fi
	if test :"${voip_cv_includes:-no}" = :no ; then
	    # VOIP header files are normally found in the strvoip package.
	    case "$streams_cv_package" in
		(LiS)
		    eval "voip_search_path=\"
			${DESTDIR}${includedir}/strvoip
			${DESTDIR}${rootdir}${oldincludedir}/strvoip
			${DESTDIR}${rootdir}/usr/include/strvoip
			${DESTDIR}${rootdir}/usr/local/include/strvoip
			${DESTDIR}${rootdir}/usr/src/strvoip/src/include
			${DESTDIR}${oldincludedir}/strvoip
			${DESTDIR}/usr/include/strvoip
			${DESTDIR}/usr/local/include/strvoip
			${DESTDIR}/usr/src/strvoip/src/include\""
		    ;;
		(LfS)
		    eval "voip_search_path=\"
			${DESTDIR}${includedir}/strvoip
			${DESTDIR}${rootdir}${oldincludedir}/strvoip
			${DESTDIR}${rootdir}/usr/include/strvoip
			${DESTDIR}${rootdir}/usr/local/include/strvoip
			${DESTDIR}${rootdir}/usr/src/strvoip/src/include
			${DESTDIR}${includedir}/streams
			${DESTDIR}${rootdir}${oldincludedir}/streams
			${DESTDIR}${rootdir}/usr/include/streams
			${DESTDIR}${rootdir}/usr/local/include/streams
			${DESTDIR}${rootdir}/usr/src/streams/include
			${DESTDIR}${oldincludedir}/strvoip
			${DESTDIR}/usr/include/strvoip
			${DESTDIR}/usr/local/include/strvoip
			${DESTDIR}/usr/src/strvoip/src/include
			${DESTDIR}${oldincludedir}/streams
			${DESTDIR}/usr/include/streams
			${DESTDIR}/usr/local/include/streams
			${DESTDIR}/usr/src/streams/include\""
		    ;;
	    esac
	    voip_search_path=`echo "$voip_search_path" | sed -e 's|\<NONE\>||g;s|//|/|g'`
	    voip_cv_includes=
	    AC_MSG_RESULT([(searching)])
	    for voip_dir in $voip_search_path ; do
		if test -d "$voip_dir" ; then
		    AC_MSG_CHECKING([for voip include directory... $voip_dir])
		    if test -r "$voip_dir/$voip_what" ; then
			voip_cv_includes="$voip_dir"
			#voip_cv_ldadd=
			#voip_cv_ldadd32=
			#voip_cv_modmap=
			#voip_cv_symver=
			#voip_cv_manpath=
			AC_MSG_RESULT([yes])
			break
		    fi
		    AC_MSG_RESULT([no])
		fi
	    done
	    AC_MSG_CHECKING([for voip include directory])
	fi
    ])
    AC_CACHE_CHECK([for voip ldadd native], [voip_cv_ldadd], [dnl
	voip_what="libvoip.la"
	voip_cv_ldadd=
	for voip_dir in $voip_cv_includes ; do
	    if test -f "$voip_dir/../../$voip_what" ; then
		voip_cv_ldadd=`echo "$voip_dir/../../$voip_what" | sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
		break
	    fi
	done
	if test -z "$voip_cv_ldadd" ; then
	    eval "voip_search_path=\"
		${DESTDIR}${rootdir}${libdir}
		${DESTDIR}${libdir}\""
	    voip_search_path=`echo "$voip_search_path" | sed -e 's|\<NONE\>|'$ac_default_prefix'|g;s|//|/|g'`
	    AC_MSG_RESULT([(searching)])
	    for voip_dir in $voip_search_path ; do
		if test -d "$voip_dir" ; then
		    AC_MSG_CHECKING([for voip ldadd native... $voip_dir])
		    if test -r "$voip_dir/$voip_what" ; then
			voip_cv_ldadd="$voip_dir/$voip_what"
			voip_cv_ldflags=
			AC_MSG_RESULT([yes])
			break
		    fi
		    AC_MSG_RESULT([no])
		fi
	    done
	    AC_MSG_CHECKING([for voip ldadd native])
	fi
    ])
    AC_CACHE_CHECK([for voip ldflags], [voip_cv_ldflags], [dnl
	voip_cv_ldflags=
	if test -z "$voip_cv_ldadd" ; then
	    voip_cv_ldflags= # '-L$(DESTDIR)$(rootdir)$(libdir) -lvoip'
	else
	    voip_cv_ldflags= # "-L$(dirname $voip_cv_ldadd)/.libs/"
	fi
    ])
    AC_CACHE_CHECK([for voip ldadd 32-bit], [voip_cv_ldadd32], [dnl
	voip_what="libvoip.la"
	voip_cv_ldadd32=
	for voip_dir in $voip_cv_includes ; do
	    if test -f "$voip_dir/../../lib32/$voip_what" ; then
		voip_cv_ldadd32=`echo "$voip_dir/../../lib32/$voip_what" | sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
		break
	    fi
	done
	if test -z "$voip_cv_ldadd32" ; then
	    eval "voip_search_path=\"
		${DESTDIR}${rootdir}${lib32dir}
		${DESTDIR}${lib32dir}\""
	    voip_search_path=`echo "$voip_search_path" | sed -e 's|\<NONE\>|'$ac_default_prefix'|g;s|//|/|g'`
	    AC_MSG_RESULT([(searching)])
	    for voip_dir in $voip_search_path ; do
		if test -d "$voip_dir" ; then
		    AC_MSG_CHECKING([for voip ldadd 32-bit... $voip_dir])
		    if test -r "$voip_dir/$voip_what" ; then
			voip_cv_ldadd32="$voip_dir/$voip_what"
			voip_cv_ldflags32=
			AC_MSG_RESULT([yes])
			break
		    fi
		    AC_MSG_RESULT([no])
		fi
	    done
	    AC_MSG_CHECKING([for voip ldadd 32-bit])
	fi
    ])
    AC_CACHE_CHECK([for voip ldflags 32-bit], [voip_cv_ldflags32], [dnl
	voip_cv_ldflags32=
	if test -z "$voip_cv_ldadd32" ; then
	    voip_cv_ldflags32= # '-L$(DESTDIR)$(rootdir)$(lib32dir) -lvoip'
	else
	    voip_cv_ldflags32= # "-L$(dirname $voip_cv_ldadd32)/.libs/"
	fi
    ])
    AC_CACHE_CHECK([for voip modmap], [voip_cv_modmap], [dnl
	voip_cv_modmap=
	for voip_dir in $voip_cv_includes ; do
	    if test -f "$voip_dir/../../Modules.map" ; then
		voip_cv_modmap=`echo "$voip_dir/../../Modules.map" | sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
		break
	    fi
	done
    ])
    AC_CACHE_CHECK([for voip symver], [voip_cv_symver], [dnl
	voip_cv_symver=
	for voip_dir in $voip_cv_includes ; do
	    if test -f "$voip_dir/../../Module.symvers" ; then
		voip_cv_symver=`echo "$voip_dir/../../Module.symvers" | sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
		break
	    fi
	done
    ])
    AC_CACHE_CHECK([for voip manpath], [voip_cv_manpath], [dnl
	voip_cv_manpath=
	for voip_dir in $voip_cv_includes ; do
	    if test -d "$voip_dir/../../doc/man" ; then
		voip_cv_manpath=`echo "$voip_dir/../../doc/man" | sed -e 's|/[[^/]][[^/]]*/\.\./|/|g;s|/[[^/]][[^/]]*/\.\./|/|g;s|/\./|/|g;s|//|/|g'`
		break
	    fi
	done
    ])
    AC_CACHE_CHECK([for voip version], [voip_cv_version], [dnl
	voip_cv_version=
	if test -z "$voip_cv_version" ; then
	    voip_what="sys/strvoip/version.h"
	    voip_file=
	    if test -n "$voip_cv_includes" ; then
		for voip_dir in $voip_cv_includes ; do
		    # old place for version
		    if test -f "$voip_dir/$voip_what" ; then
			voip_file="$voip_dir/$voip_what"
			break
		    fi
		    # new place for version
		    if test -n "$linux_cv_k_release" ; then
dnl		    if linux_cv_k_release is not defined (no _LINUX_KERNEL) then
dnl		    this will just not be set
			if test -f "$voip_dir/$linux_cv_k_release/$target_cpu/$voip_what" ; then
			    voip_file="$voip_dir/$linux_cv_k_release/$target_cpu/$voip_what"
			    break
			fi
		    fi
		done
	    fi
	    if test :${voip_file:-no} != :no ; then
		voip_cv_version=`grep '#define.*\<STRVOIP_VERSION\>' $voip_file 2>/dev/null | sed -e 's|^[^"]*"||;s|".*$||'`
	    fi
	fi
	if test -z "$voip_cv_version" ; then
	    voip_epoch=
	    voip_version=
	    voip_package=
	    voip_release=
	    voip_patchlevel=
	    if test -n "$voip_cv_includes" ; then
		for voip_dir in $voip_cv_includes ; do
		    if test -z "$voip_epoch" -a -s "$voip_dir/../.rpmepoch" ; then
			voip_epoch=`cat $voip_dir/../.rpmepoch`
		    fi
		    if test -z "$voip_epoch" -a -s "$voip_dir/../../.rpmepoch" ; then
			voip_epoch=`cat $voip_dir/../../.rpmepoch`
		    fi
		    if test -z "$voip_version" -a -s "$voip_dir/../.version" ; then
			voip_version=`cat $voip_dir/../.version`
		    fi
		    if test -z "$voip_version" -a -s "$voip_dir/../../.version" ; then
			voip_version=`cat $voip_dir/../../.version`
		    fi
		    if test -z "$voip_version" ; then
			if test -z "$voip_version" -a -s "$voip_dir/../configure" ; then
			    voip_version=`grep '^PACKAGE_VERSION=' $voip_dir/../configure | head -1 | sed -e "s,^[[^']]*',,;s,'.*[$],,"`
			fi
			if test -z "$voip_version" -a -s "$voip_dir/../../configure" ; then
			    voip_version=`grep '^PACKAGE_VERSION=' $voip_dir/../../configure | head -1 | sed -e "s,^[[^']]*',,;s,'.*[$],,"`
			fi
			if test -z "$voip_package" -a -s "$voip_dir/../.pkgrelease" ; then
			    voip_package=`cat $voip_dir/../.pkgrelease`
			fi
			if test -z "$voip_package" -a -s "$voip_dir/../../.pkgrelease" ; then
			    voip_package=`cat $voip_dir/../../.pkgrelease`
			fi
			if test -z "$voip_patchlevel" -a -s "$voip_dir/../.pkgpatchlevel" ; then
			    voip_patchlevel=`cat $voip_dir/../.pkgpatchlevel`
			fi
			if test -z "$voip_patchlevel" -a -s "$voip_dir/../../.pkgpatchlevel" ; then
			    voip_patchlevel=`cat $voip_dir/../../.pkgpatchlevel`
			fi
			if test -n "$voip_version" -a -n "$voip_package" ; then
			    voip_version="$voip_version.$voip_package${voip_patchlevel:+.$voip_patchlevel}"
			else
			    voip_version=
			fi
		    fi
		    if test -z "$voip_release" -a -s "$voip_dir/../.rpmrelease" ; then
			voip_release=`cat $voip_dir/../.rpmrelease`
		    fi
		    if test -z "$voip_release" -a -s "$voip_dir/../../.rpmrelease" ; then
			voip_release=`cat $voip_dir/../../.rpmrelease`
		    fi
		done
	    fi
	    if test -n "$voip_epoch" -a -n "$voip_version" -a -n "$voip_release" ; then
		voip_cv_version="$voip_epoch:$voip_version-$voip_release"
	    fi
	fi
    ])
    voip_what="sys/strvoip/config.h"
    AC_CACHE_CHECK([for voip $voip_what], [voip_cv_config], [dnl
	voip_cv_config=
	if test -n "$voip_cv_includes" ; then
	    AC_MSG_RESULT([(searching $voip_cv_includes)])
	    for voip_dir in $voip_cv_includes ; do
		# old place for config
		AC_MSG_CHECKING([for voip $voip_what... $voip_dir])
		if test -f "$voip_dir/$voip_what" ; then
		    voip_cv_config="$voip_dir/$voip_what"
		    AC_MSG_RESULT([yes])
		    break
		fi
		AC_MSG_RESULT([no])
		# new place for config
		if test -n "$linux_cv_k_release" ; then
dnl		    if linux_cv_k_release is not defined (no _LINUX_KERNEL) then
dnl		    this will just not be set
		    AC_MSG_CHECKING([for voip $voip_what... $voip_dir/$linux_cv_k_release/$target_cpu])
		    if test -f "$voip_dir/$linux_cv_k_release/$target_cpu/$voip_what" ; then
			voip_cv_config="$voip_dir/$linux_cv_k_release/$target_cpu/$voip_what"
			AC_MSG_RESULT([yes])
			break
		    fi
		    AC_MSG_RESULT([no])
		fi
	    done
	    AC_MSG_CHECKING([for voip $voip_what])
	fi
    ])
    voip_what="sys/strvoip/modversions.h"
    AC_CACHE_CHECK([for voip $voip_what], [voip_cv_modversions], [dnl
	voip_cv_modversions=
dnl	if linux_cv_k_ko_modules is not defined (no _LINUX_KERNEL) then we
dnl	assume normal objects
	if test :"${linux_cv_k_ko_modules:-no}" = :no ; then
	    if test -n "$voip_cv_includes" ; then
		AC_MSG_RESULT([(searching $voip_cv_includes)])
		for voip_dir in $voip_cv_includes ; do
		    # old place for modversions
		    AC_MSG_CHECKING([for voip $voip_what... $voip_dir])
		    if test -f "$voip_dir/$voip_what" ; then
			voip_cv_modversions="$voip_dir/$voip_what"
			AC_MSG_RESULT([yes])
			break
		    fi
		    AC_MSG_RESULT([no])
		    # new place for modversions
		    if test -n "$linux_cv_k_release" ; then
dnl			if linux_cv_k_release is not defined (no _LINUX_KERNEL)
dnl			then this will just not be set
			AC_MSG_CHECKING([for voip $voip_what... $voip_dir/$linux_cv_k_release/$target_cpu])
			if test -f "$voip_dir/$linux_cv_k_release/$target_cpu/$voip_what" ; then
			    voip_cv_includes="$voip_dir/$linux_cv_k_release/$target_cpu $voip_cv_includes"
			    voip_cv_modversions="$voip_dir/$linux_cv_k_release/$target_cpu/$voip_what"
			    AC_MSG_RESULT([yes])
			    break
			fi
			AC_MSG_RESULT([no])
		    fi
		done
		AC_MSG_CHECKING([for voip $voip_what])
	    fi
	fi
    ])
    AC_MSG_CHECKING([for voip added configure arguments])
dnl Older rpms (particularly those used by SuSE) are too stupid to handle --with
dnl and --without rpmopt syntax, so convert to the equivalent --define syntax.
dnl Also, I don't know that even rpm 4.2 handles --with xxx=yyy properly, so we
dnl use defines.
    if test -z "$with_voip" ; then
	if test :"${voip_cv_includes:-no}" = :no ; then
	    PACKAGE_RPMOPTIONS="${PACKAGE_RPMOPTIONS}${PACKAGE_RPMOPTIONS:+ }--define \"_with_voip --with-voip\""
	    PACKAGE_DEBOPTIONS="${PACKAGE_DEBOPTIONS}${PACKAGE_DEBOPTIONS:+ }'--with-voip'"
	    AC_MSG_RESULT([--with-voip])
	else
	    PACKAGE_RPMOPTIONS="${PACKAGE_RPMOPTIONS}${PACKAGE_RPMOPTIONS:+ }--define \"_without_voip --without-voip\""
	    PACKAGE_DEBOPTIONS="${PACKAGE_DEBOPTIONS}${PACKAGE_DEBOPTIONS:+ }'--without-voip'"
	    AC_MSG_RESULT([--without-voip])
	fi
    else
	AC_MSG_RESULT([--with-voip="$with_voip"])
    fi
])# _VOIP_CHECK_HEADERS
# =============================================================================

# =============================================================================
# _VOIP_KERNEL
# -----------------------------------------------------------------------------
AC_DEFUN([_VOIP_KERNEL], [dnl
])# _VOIP_KERNEL
# =============================================================================

# =============================================================================
# _VOIP_OUTPUT
# -----------------------------------------------------------------------------
AC_DEFUN([_VOIP_OUTPUT], [dnl
    _VOIP_DEFINES
])# _VOIP_OUTPUT
# =============================================================================

# =============================================================================
# _VOIP_DEFINES
# -----------------------------------------------------------------------------
AC_DEFUN([_VOIP_DEFINES], [dnl
    if test :"${voip_cv_modversions:-no}" != :no ; then
	AC_DEFINE_UNQUOTED([HAVE_SYS_VOIP_MODVERSIONS_H], [1], [Define when
	    the STREAMS VOIP release supports module versions such as
	    the OpenSS7 autoconf releases.])
    fi
    VOIP_CPPFLAGS="${VOIP_CPPFLAGS:+ }${VOIP_CPPFLAGS}"
    VOIP_LDADD="$voip_cv_ldadd"
    VOIP_LDADD32="$voip_cv_ldadd32"
    VOIP_LDFLAGS="$voip_cv_ldflags"
    VOIP_LDFLAGS32="$voip_cv_ldflags32"
    VOIP_MODMAP="$voip_cv_modmap"
    VOIP_SYMVER="$voip_cv_symver"
    VOIP_MANPATH="$voip_cv_manpath"
    VOIP_VERSION="$voip_cv_version"
    MODPOST_INPUTS="${MODPOST_INPUTS}${VOIP_SYMVER:+${MODPOST_INPUTS:+ }${VOIP_SYMVER}}"
    AC_DEFINE_UNQUOTED([_XOPEN_SOURCE], [600], [dnl
	Define for SuSv3.  This is necessary for LiS and LfS and strvoip for
	that matter.
    ])
])# _VOIP_DEFINES
# =============================================================================

# =============================================================================
# _VOIP_USER
# -----------------------------------------------------------------------------
AC_DEFUN([_VOIP_USER], [dnl
])# _VOIP_USER
# =============================================================================

# =============================================================================
# _VOIP_
# -----------------------------------------------------------------------------
AC_DEFUN([_VOIP_], [dnl
])# _VOIP_
# =============================================================================

# =============================================================================
#
# $Log: voip.m4,v $
# Revision 0.9.2.22  2008-10-30 11:36:16  brian
# - corrections to build
#
# Revision 0.9.2.21  2008-10-26 12:17:19  brian
# - update package discovery macros
#
# Revision 0.9.2.20  2008-09-28 19:10:58  brian
# - quotation corrections
#
# Revision 0.9.2.19  2008-09-28 18:42:57  brian
# - corrections
#
# Revision 0.9.2.18  2008-09-28 17:48:30  brian
# - more version number corrections
#
# Revision 0.9.2.17  2008-09-28 16:50:56  brian
# - parsing correction and addition of patchlevel
#
# Revision 0.9.2.16  2008-04-28 09:41:04  brian
# - updated headers for release
#
# Revision 0.9.2.15  2007/08/12 19:05:32  brian
# - rearrange and update headers
#
# Revision 0.9.2.14  2007/03/07 10:12:59  brian
# - more corrections
#
# Revision 0.9.2.13  2007/03/07 09:24:08  brian
# - further corrections
#
# Revision 0.9.2.12  2007/03/07 07:29:22  brian
# - search harder for versions
#
# Revision 0.9.2.11  2007/03/06 23:39:54  brian
# - more corrections
#
# Revision 0.9.2.10  2007/03/04 23:26:40  brian
# - corrected modversions directory
#
# Revision 0.9.2.9  2007/03/04 23:14:43  brian
# - better search for modversions
#
# Revision 0.9.2.8  2007/03/01 07:17:25  brian
# - updating common build process
#
# Revision 0.9.2.7  2007/03/01 06:38:15  brian
# - updates to common build process
#
# Revision 0.9.2.6  2007/03/01 01:45:16  brian
# - updating build process
#
# Revision 0.9.2.5  2007/03/01 00:10:19  brian
# - update to build process for 2.4 kernels
#
# Revision 0.9.2.4  2007/02/28 11:51:32  brian
# - make sure build directory exists
#
# Revision 0.9.2.3  2006-12-28 08:32:32  brian
# - use cache names for master src and build directories
#
# Revision 0.9.2.2  2006/10/16 11:56:11  brian
# - correct what to search for
#
# Revision 0.9.2.1  2006/10/16 08:28:02  brian
# - added new package discovery macros
#
# =============================================================================
# 
# Copyright (c) 2001-2008  OpenSS7 Corporation <http://www.openss7.com/>
# Copyright (c) 1997-2000  Brian F. G. Bidulock <bidulock@openss7.org>
# 
# =============================================================================
# ENDING OF SEPARATE COPYRIGHT MATERIAL
# =============================================================================
# vim: ft=config sw=4 noet nocin nosi com=b\:#,b\:dnl,b\:***,b\:@%\:@ fo+=tcqlorn