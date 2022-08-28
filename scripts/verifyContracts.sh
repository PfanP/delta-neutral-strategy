
# @deprecated

# ConcaveOracle
read -p "Enter ConcaveOracle's Address(Leave it empty if it's already verified): " CONCAVE_ORACLE_ADDRESS
# if CONCAVE_ORACLE_ADDRESS is not empty
if [ -n "$CONCAVE_ORACLE_ADDRESS" ]; then
    echo "ConcaveOracleAddress: $CONCAVE_ORACLE_ADDRESS"
    npx hardhat verify --network goerli $CONCAVE_ORACLE_ADDRESS 
else
    echo "ConcaveOracleAddress is empty"
fi

read -p "Enter BaseOracle's Address: (Leave it empty if it's already verified): " BASE_ORACLE_ADDRESS
if [ -n "$BASE_ORACLE_ADDRESS" ]; then
    echo "BaseOracle: $BASE_ORACLE_ADDRESS"
    npx hardhat verify --network goerli $BASE_ORACLE_ADDRESS 
else
    echo "BaseOracle is empty"
fi

# Ran's TODO: How to verify Vyper through command-line
# read -p "Enter Vault's Address: (Leave it empty if it's already verified): " VAULT_ADDRESS
# if [ -n "$VAULT_ADDRESS" ]; then
#     echo "VaultAddress: $VAULT_ADDRESS"
#     npx hardhat verify --network goerli $VAULT_ADDRESS 
# else
#     echo "VaultAddress is empty"
# fi

read -p "Enter Strategy's Address: (Leave it empty if it's already verified): " STRATEGY_ADDRESS
if [ -n "$STRATEGY_ADDRESS" ]; then
    echo "Strategy: $STRATEGY_ADDRESS"
    npx hardhat verify \
        --network goerli \
        --constructor-args strategy_constructor_param.js \
        $STRATEGY_ADDRESS 
else
    echo "Strategy is empty"
fi