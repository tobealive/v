// vtest retry: 3
import os
import rand
import test_utils

const vexe = os.quoted_path(@VEXE)
const test_path = os.join_path(os.vtmp_dir(), 'vpm_remove_test_${rand.ulid()}')

fn testsuite_begin() {
	$if !network ? {
		eprintln('> skipping ${@FILE}, when `-d network` is missing')
		exit(0)
	}
	test_utils.set_test_env(test_path)
}

fn testsuite_end() {
	os.rmdir_all(test_path) or {}
}

fn test_remove() {
	println('started')
	os.execute_or_exit('${vexe} install https://github.com/hungrybluedev/xlsx')
	res := os.execute('${vexe} remove xlsx')
	assert res.exit_code == 0, res.str()
	println(os.ls(test_path)!)
}

fn test_remove2() {
	println('started')
	println(os.ls(test_path)!)
}
