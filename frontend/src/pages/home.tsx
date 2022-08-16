import { Heading, Text, VStack } from '@chakra-ui/react';
import { useState } from 'react';
import { useContractRead } from 'wagmi';

import { abi, address } from '../data/data';

/* eslint-disable react/jsx-no-constructed-context-values */
function Home() {
    const [loans, setLoans] = useState(0);
    const [reserves, setReserves] = useState();

    const { data: liquidity } = useContractRead(
        {
            addressOrName: address,
            contractInterface: abi,
        },
        'getPoolReserves'
    );

    const { data: share } = useContractRead(
        {
            addressOrName: address,
            contractInterface: abi,
        },
        'getTotalShares'
    );

    return (
        <VStack>
            <Heading>Protocol Statistics</Heading>
            <Text>{`Total Pool Liquidity ${liquidity} USDC`}</Text>
            <Text>{`Total Share ${share}`}</Text>
        </VStack>
    );
}

export default Home;
