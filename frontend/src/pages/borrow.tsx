import {
    Box,
    Text,
    Input,
    Button,
    Heading,
    Stack,
    VStack,
} from '@chakra-ui/react';
import type { VerificationResponse } from '@worldcoin/id';
import worldId from '@worldcoin/id';
import { useEffect, useState } from 'react';
import React from 'react';
import {
    useAccount,
    useContractRead,
    useContractWrite,
    useWaitForTransaction,
} from 'wagmi';

import BorrowerInfo from '../components/BorrowerInfo';
import PersonhoodInterface from '../sdk/abi/MediciPool.abi.json';

const worldIDConfig = {
    addressOrName: process.env.REACT_APP_WORLDID_ADDR,
    contractInterface: PersonhoodInterface.abi,
};

// borrow limit
// amount to pay back
// time limit
const BorrowDashboard = () => {
    return (
        <VStack rounded="lg" bg="purple.50" as="section" w="100%" p={5}>
            <Text fontSize="sm">{`Borrow Limit ${0}`}</Text>
            <Text fontSize="sm">{`Interest ${0}`}</Text>
            <Text fontSize="sm">{`Due by ${0}`}</Text>
            <BorrowerInfo />
        </VStack>
    );
};

const WorldCoinButton: React.FC = () => {
    return (
        <VStack
            bg={'gray.50'}
            rounded={'xl'}
            w="100%"
            p={{ base: 4, sm: 6, md: 8 }}
            spacing={{ base: 5 }}
            maxW={{ lg: 'lg' }}
        >
            <Text fontWeight="bold">Sign in with World Coin to borrow</Text>
            <Box id="world-coin-button"></Box>
        </VStack>
    );
};

function Borrow() {
    const { walletAddress, isConnected } = useAccount();
    const [worldIDProof, setWorldIDProof] =
        React.useState<VerificationResponse | null>(null);
    const [borrowLimit, setBorrowLimit] = useState(0);

    const [interest, setInterest] = useState(0);
    const [dueDate, setDueDate] = useState();

    const borrowAction = async () => {
        if (!worldIDProof) {
            throw 'World ID missing';
        }
    };

    const { data: allowance } = useContractRead(
        worldIDConfig,
        'checkAlreadyExists',
        {
            args: ['0xb1b4e269dD0D19d9D49f3a95bF6c2c15f13E7943'],
            watch: true,
        }
    );

    useEffect(() => {
        const setUpWorldId = async () => {
            if (!worldId.isInitialized()) {
                worldId.init('world-coin-button', {
                    enable_telemetry: true,
                    action_id: 'wid_staging_b04e5e2fee1ae804a7ac27a9999f717f',
                    signal: 'example signal',
                    app_name: 'unique_borrowers',
                    signal_description: 'check if the borrower is unique',
                });
            }

            if (!worldId.isEnabled()) {
                await worldId.enable();
            }
        };

        setUpWorldId();
    });

    useEffect(() => {
        if (isConnected) console.log('Connected to ', walletAddress);
    }, [isConnected]);

    if (isConnected) console.log('Connected to ', walletAddress);
    else console.log('Not connected');

    return (
        <VStack spacing={5}>
            <WorldCoinButton />
            <Stack
                bg={'gray.50'}
                rounded={'xl'}
                w="100%"
                p={{ base: 4, sm: 6, md: 8 }}
                spacing={{ base: 8 }}
                maxW={{ lg: 'lg' }}
            >
                <Stack spacing={4}>
                    <Heading
                        color={'gray.800'}
                        lineHeight={1.1}
                        fontSize={{ base: '2xl', sm: '3xl', md: '4xl' }}
                    >
                        Borrow flexibly
                        <Text
                            as={'span'}
                            bgGradient="linear(to-r, red.400,pink.400)"
                            bgClip="text"
                        >
                            !
                        </Text>
                    </Heading>
                    <Text
                        color={'gray.500'}
                        fontSize={{ base: 'sm', sm: 'md' }}
                    >
                        Pick your loan amount, APR and time period. We will
                        match you with the best lender.
                    </Text>
                </Stack>
                <Box as={'form'} mt={10}>
                    <Stack spacing={4}>
                        <Input
                            placeholder="Loan Amount"
                            bg={'gray.100'}
                            border={0}
                            color={'gray.500'}
                            _placeholder={{
                                color: 'gray.500',
                            }}
                        />
                        <Input
                            placeholder="APR"
                            bg={'gray.100'}
                            border={0}
                            color={'gray.500'}
                            _placeholder={{
                                color: 'gray.500',
                            }}
                        />
                        <Input
                            placeholder="Time Period"
                            bg={'gray.100'}
                            border={0}
                            color={'gray.500'}
                            _placeholder={{
                                color: 'gray.500',
                            }}
                        />
                    </Stack>
                    <Button
                        fontFamily={'heading'}
                        mt={8}
                        w={'full'}
                        bgGradient="linear(to-r, red.400,pink.400)"
                        color={'white'}
                        _hover={{
                            bgGradient: 'linear(to-r, red.400,pink.400)',
                            boxShadow: 'xl',
                        }}
                    >
                        Request Loan
                    </Button>
                </Box>
                form
            </Stack>
        </VStack>
        // <>{worldId.isEnabled() ? <BorrowDashboard /> : <WorldCoinButton />}</>
        // {walletAddress && (
        //           <WorldIDComponent
        //             signal={walletAddress}
        //             setProof={(proof) => setWorldIDProof(proof)}
        //           />
        //         )}
    );
}

export default Borrow;
