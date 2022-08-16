import * as React from 'react';
import { Route, Routes } from 'react-router-dom';

import Approve from '../pages/approve';
import Borrow from '../pages/borrow';
import Deposit from '../pages/deposit';
import Home from '../pages/home';

const routes = [
    {
        path: '/',
        name: 'Home',
        component: Home,
    },
    {
        path: '/deposit',
        name: 'Deposit',
        component: Deposit,
    },
    {
        path: '/borrow',
        name: 'Borrow',
        component: Borrow,
    },
    {
        path: '/approve',
        name: 'Approve',
        component: Approve,
    },
];

function Navigation(walletAddress: string) {
    return (
        <Routes>
            {routes.map((route) => (
                <Route
                    path={route.path}
                    element={<route.component />}
                    key={route.toString()}
                    // walletAddress={walletAddress}
                />
            ))}
        </Routes>
    );
}

export default Navigation;
