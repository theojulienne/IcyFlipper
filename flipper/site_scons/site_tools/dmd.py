# imports the default SCons DMD tool, but adds support for ldmd
import SCons.Tool.dmd
import os

def generate(env):
	dc = env.Detect(['dmd', 'gdmd', 'ldmd'])
	ar = env['ARCOM']
	ld = env['LINKCOM']
	SCons.Tool.dmd.generate( env )
	if env['PLATFORM'] == 'win32' and dc == 'gdmd':
		print 'Removing "smart" linker, because we\'re using gdmd (so ld should link)'
		env['CC'] = 'gdc'
		env['ARCOM'] = ar 
		env['LINKCOM'] = ld
	env['DC'] = dc

def exists(env):
	return env.Detect(['dmd', 'gdmd', 'ldmd'])