

module_a=$1
module_b=$2


diff $module_a/configure/E3/CONFIG_E3_PATH $module_b/configure/E3/CONFIG_E3_PATH

echo ">>>>>>>>>>>>>>> "

diff $module_a/configure/E3/RULES_E3 $module_b/configure/E3/RULES_E3


echo ">>>>>>>>>.>>"


