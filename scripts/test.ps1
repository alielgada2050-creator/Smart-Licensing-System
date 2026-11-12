$ErrorActionPreference = 'Stop'

python -m unittest discover -s server -p "test_*.py" -v
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

flutter test
exit $LASTEXITCODE
