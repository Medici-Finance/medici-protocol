import {
    Button,
    HStack,
    Input,
    InputGroup,
    InputLeftAddon,
    Text,
    useToast,
    VStack,
} from '@chakra-ui/react';
import React, { createRef } from 'react';
import { AiOutlineMenu as EthereumCurrency } from 'react-icons/ai';
import {
    useContractRead,
    useContractWrite,
    useWaitForTransaction,
} from 'wagmi';

import ApproverInfo from '../components/ApproverInfo';
import MediciPoolInterface from '../sdk/abi/MediciPool.abi.json';
import USDCTokenInterface from '../sdk/abi/USDCToken.abi.json';

const contractConfig = {
    addressOrName: '0x35bfa40f365f8de7707749ba5a483dfef99ed2c9',
    contractInterface: MediciPoolInterface.abi,
};

const usdcConfig = {
    addressOrName: '0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C',
    contractInterface: USDCTokenInterface,
};

function Deposit() {
    const textInput: React.RefObject<HTMLInputElement> =
        createRef<HTMLInputElement>();
    const [depositAmount, setDepositAmount] = React.useState(5);

    const { write: approveUSDC } = useContractWrite(usdcConfig, 'approve', {
        args: ['0x35bfa40f365f8de7707749ba5a483dfef99ed2c9', BigInt(10 ** 25)],
        overrides: { gasLimit: 1e7 },
    });

    const { data: allowance } = useContractRead(usdcConfig, 'allowance', {
        args: [
            '0xb1b4e269dD0D19d9D49f3a95bF6c2c15f13E7943',
            '0x35bfa40f365f8de7707749ba5a483dfef99ed2c9',
        ],
        watch: true,
    });

    const {
        data: depositData,
        error: depositError,
        write: poolDeposit,
        isLoading: isDepositLoading,
        isSuccess: isDepositSuccess,
    } = useContractWrite(contractConfig, 'deposit');

    const handleDeposit = async () => {
        await poolDeposit({
            args: [BigInt(1 ** 18)],
            overrides: { gasLimit: 1e7 },
        });
        toast({
            title: 'Waiting for transaction ...',
            status: 'info',
            isClosable: true,
        });
    };

    React.useEffect(() => {
        console.log('processing deposit\n');
        console.log('data:', depositData);
        console.log('error:', depositError);
        console.log('loading:', isDepositLoading);
        console.log('success:', isDepositSuccess);
    }, [depositData, depositError]);

    const { isSuccess: txSuccess, error: txError } = useWaitForTransaction({
        confirmations: 1,
        hash: depositData?.hash,
    });

    React.useEffect(() => {
        if (depositError) {
            toast({
                title: depositError.message,
                status: 'error',
                isClosable: true,
            });
        }
    }, [depositError]);

    React.useEffect(() => {
        console.log('actual error:', txError);

        if (txError) {
            toast({
                title: txError.message,
                status: 'error',
                isClosable: true,
            });
        }
    }, [txError]);

    const depositSuccess = txSuccess;
    const toast = useToast();

    return (
        <>
            <VStack
                justifyContent="start"
                bg="purple.50"
                rounded="lg"
                p={5}
                as="section"
                h="40vh"
                alignItems="center"
            >
                <Text textAlign="left" fontWeight="bold" w="100%">
                    Deposit to lending pool
                </Text>
                <HStack w="100%">
                    <InputGroup>
                        <InputLeftAddon
                            pointerEvents="none"
                            children={<EthereumCurrency />}
                        />
                        <Input
                            placeholder="Amount"
                            variant="outline"
                            ref={textInput}
                        />
                    </InputGroup>
                    <Button onClick={() => approveUSDC()} colorScheme="red">
                        Approve
                    </Button>
                    <Button
                        onClick={() => handleDeposit()}
                        colorScheme="purple"
                    >
                        Deposit
                    </Button>
                </HStack>
                <ApproverInfo />
            </VStack>
        </>
    );
}

export default Deposit;
