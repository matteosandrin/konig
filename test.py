import os
import subprocess

TEST_DIR = "./test/"
tests = []

for f in os.listdir(TEST_DIR):
    if f.endswith(".ko"):
        tests.append(os.path.splitext(f)[0])

failed = 0

for test_file in tests:

    print("[+] Running test \"{}\"...".format(test_file))

    os.system("./compile.sh test/{}.ko > /dev/null".format(test_file))
    os.system("./{}.out > test/{}.txt".format(test_file, test_file))
    res = subprocess.run(
        [
            "diff",
            "test/{}.txt".format(test_file),
            "test/{}.res".format(test_file)
        ],stdout=subprocess.PIPE)
    
    if len(res.stdout) == 0:
        print("[+] test \"{}\" PASSED.".format(test_file))
    else:
        print("[!] test \"{}\" FAILED. (!!!)".format(test_file))
        failed += 1

os.system("rm *.out test/*.txt")

print("")
if failed == 0: 
    print("[+] {}/{} test cases PASSED".format(len(tests), len(tests)))
else:
    print("[!] {}/{} test cases FAILED (!!!)".format(failed, len(tests)))