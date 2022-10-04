import fs from 'fs';
import {
  attestFromEth,
  createWrappedOnEth,
  getEmitterAddressEth,
  getEmitterAddressSolana,
  getForeignAssetEth,
  parseSequenceFromLogEth,
  redeemOnEth,
  setDefaultWasm,
  transferFromEthNative,
  tryNativeToUint8Array,
} from '@certusone/wormhole-sdk';
import * as ethers from 'ethers';
import fetch from 'node-fetch';
import { promisify } from 'util';

const exec = promisify(require('child_process').exec);
const config = JSON.parse(fs.readFileSync('./xdapp.config.json').toString());

// let ABI = {};
// try {
//   ABI = JSON.parse(fs.readFileSync('./chains/evm/out/MediciCore.sol/MediciCore.json').toString()).abi;
// } catch (e) {
//   // fail silenty
//   // The only time this fails is when deploy hasn't been called, in which case, this isn't needed
// }

/**
 * 1. Deploy on chain core contract
 * @param src The network to deploy
 */
export async function deploy(src: string, core: boolean) {
  const network = config.local[src];
  const scriptFn = core ? 'DeployCore' : 'DeployPeriphery';

  const { stdout, stderr } = await exec(
    `forge script test/Medici.s.sol:Medici --rpc-url ${network.rpc} --broadcast -vvv`
  );

  if (stderr) {
    throw new Error(stderr);
  }

  let deploymentAddress;
  if (stdout) {
    console.log(stdout);
    deploymentAddress = stdout.split('Deployed to: ')[1].split('\n')[0].trim();
    fs.writeFileSync(
      `./deployinfo/${src}.deploy.json`,
      JSON.stringify(
        {
          address: deploymentAddress,
          tokenAddress: deploymentAddress,
          tokenReceipientAddress: deploymentAddress,
          vaas: [],
        },
        null,
        4
      )
    );
  }
}

export async function registerApp(src: string, target: string) {
  const key = fs.readFileSync(`keypairs/${src}.key`).toString();

  const srcNetwork = config.local[src];
  const targetNetwork = config.local[target];
  let srcDeploymentInfo;
  let targetDeploymentInfo;
  let targetEmitter;

  try {
    srcDeploymentInfo = JSON.parse(fs.readFileSync(`./deployinfo/${src}.deploy.json`).toString());
  } catch (e) {
    throw new Error(`${src} is not deployed yet`);
  }

  try {
    targetDeploymentInfo = JSON.parse(fs.readFileSync(`./deployinfo/${target}.deploy.json`).toString());
  } catch (e) {
    throw new Error(`${target} is not deployed yet`);
  }

  switch (targetNetwork['type']) {
    case 'evm':
      targetEmitter = getEmitterAddressEth(targetDeploymentInfo['address']);
      break;
    case 'solana':
      //   setDefaultWasm('node'); // *sigh*
      //   targetEmitter = await getEmitterAddressSolana(targetDeploymentInfo['address']);
      break;
  }

  const emitterBuffer = Buffer.from(targetEmitter, 'hex');
  const signer = new ethers.Wallet(key).connect(new ethers.providers.JsonRpcProvider(srcNetwork.rpc));

  // const core = new ethers.Contract(srcDeploymentInfo.address, ABI, signer);

  // const tx = await core.registerApplicationContracts(targetNetwork.wormholeChainId, emitterBuffer);
  console.log(`Registered ${target} application on ${src}`);
}

export async function authenticate() {}

export async function loanRequest() {}
