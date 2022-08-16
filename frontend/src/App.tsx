import { ChakraProvider } from '@chakra-ui/react';
import {
    getDefaultWallets,
    lightTheme,
    RainbowKitProvider,
} from '@rainbow-me/rainbowkit';
import React, { FC, useState } from 'react';
import { chain, configureChains, createClient, WagmiConfig } from 'wagmi';
import { alchemyProvider } from 'wagmi/providers/alchemy';
import { publicProvider } from 'wagmi/providers/public';
import { createContainer } from 'react-tracked';

const alchemyId = process.env.REACT_APP_ALCHEMY_KEY;

import Layout from './layouts/layout';

const useAccount = () =>
    useState({
        walletAddress: '',
    });

export const { Provider, useTracked } = createContainer(useAccount);

const { chains, provider } = configureChains(
    [chain.polygonMumbai, chain.goerli],
    [alchemyProvider({ alchemyId }), publicProvider()]
);

const { connectors } = getDefaultWallets({
    appName: 'Medici Finance',
    chains,
});

const wagmiClient = createClient({
    autoConnect: true,
    connectors,
    provider,
});

export const App: FC = () => {
    console.log(process.env.REACT_APP_ALCHEMY_KEY);

    return (
        <Provider>
            <WagmiConfig client={wagmiClient}>
                <RainbowKitProvider
                    chains={chains}
                    theme={lightTheme({
                        accentColor: '#7b3fe4',
                        accentColorForeground: 'white',
                        borderRadius: 'medium',
                    })}
                >
                    <ChakraProvider>
                        <Layout />
                    </ChakraProvider>
                </RainbowKitProvider>
            </WagmiConfig>
        </Provider>
    );
};
