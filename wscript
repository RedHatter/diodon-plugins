#! /usr/bin/env python
# encoding: utf-8

import os

top = '.'
out = '_build_'


def options(opt):
    opt.load('python')
    opt.tool_options('compiler_c')
    opt.tool_options('vala')
    opt.tool_options('gnu_dirs')


def configure(conf):
    conf.load('compiler_c gnu_dirs')
    conf.load('vala', funs='')
    conf.load('python')
    conf.load('glib2')
    conf.env['PLUGINS_DIR'] = os.path.join(conf.env['LIBDIR'], 'diodon', 'plugins')

    conf.check_vala(min_version=(0, 16, 0))

    conf.check_cfg(package='diodon',      uselib_store='DIODON', atleast_version='1.6.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='libpeas-1.0', uselib_store='PEAS',   atleast_version='1.1.0', mandatory=1, args='--cflags --libs')
    conf.check_cfg(package='libpeas-gtk-1.0', uselib_store='PEASGTK',   atleast_version='1.1.0', mandatory=1, args='--cflags --libs')

    conf.env['CFLAGS'] = ['-O0', '-g3', '-w']
    conf.env['VALAFLAGS'] = ['-g', '-v', '--enable-checking']


def build(bld):
    bld.add_subdirs('plugins/paste-all')
    bld.add_subdirs('plugins/edit')
    bld.add_subdirs('plugins/features')
    bld.add_subdirs('plugins/numbers')
    bld.add_subdirs('plugins/pop')
    bld.add_subdirs('plugins/dbus-controller')
