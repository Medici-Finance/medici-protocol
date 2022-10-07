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
import { promisify } from 'util';
import * as dotenv from 'dotenv';

dotenv.config();

const exec = promisify(require('child_process').exec);
const config = JSON.parse(fs.readFileSync('./xdapp.config.json').toString());

// let ABI = {};
// try {
//   ABI = JSON.parse(fs.readFileSync('./chains/evm/out/MediciCore.sol/MediciCore.json').toString()).abi;
// } catch (e) {
//   // fail silenty
//   // The only time this fails is when deploy hasn't been called, in which case, this isn't needed
// }

// `forge script test/Medici.s.sol:Medici --legacy --rpc-url ${} -g 1000 --json`,

// `forge build && forge create test/Medici.s.sol:Medici --legacy --rpc-url ${network.rpc} --broadcast -vvv`,
// `forge build && forge create --legacy --rpc-url ${network.rpc} --private-key ${network.privateKey} test/LocalConfig.sol:LocalConfig src/core/MediciCore.sol:MediciCore && exit`

/**
 * 1. Deploy on chain core contract
 * @param chain The network to deploy
 */
export async function deploy(chain: string, core: boolean) {
  const network = config.testnet[chain];

  const scriptFn = core ? 'deployCore' : chain === 'goerli' ? 'deployPeripheryGeorli' : 'deployPeripheryFuji';

  const script = `forge script test/Medici.s.sol:Medici --sig "${scriptFn}()" --rpc-url ${network.rpc} --broadcast -vvv`;

  const { stdout, stderr } = await exec(script);

  if (stderr) {
    throw new Error(stderr);
  }

  let deploymentAddress;
  if (stdout) {
    let tx = JSON.parse(fs.readFileSync('./broadcast/Medici.s.sol/5/deployCore-latest.json').toString()).transactions;
    for (const t of tx) {
      if (t.contractName === 'MediciCore') {
        deploymentAddress = t.contractAddress;
      }
    }
    const emittedVAAs = []; //Resets the emittedVAAs

    fs.writeFileSync(
      `./deployinfo/${chain}.deploy.json`,
      JSON.stringify(
        {
          address: deploymentAddress,
          vaas: emittedVAAs,
        },
        null,
        4
      )
    );
  }
}

export async function registerApp(src: string, target: string, isCore: boolean) {
  const srcNetwork = config.testnet[src];
  const targetNetwork = config.testnet[target];
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

  console.log(targetDeploymentInfo['address']);
  const emitterBuffer = Buffer.from(targetEmitter, 'hex');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY).connect(
    new ethers.providers.JsonRpcProvider(srcNetwork.rpc)
  );

  if (isCore) {
    const core = new ethers.Contract(
      srcDeploymentInfo.address,
      JSON.parse(fs.readFileSync('./out/MediciCore.sol/MediciCore.json').toString()).abi,
      signer
    );

    const tx = await core.registerChain(targetNetwork.wormholeChainId, emitterBuffer);
  } else {
    const periphery = new ethers.Contract(
      srcDeploymentInfo.address,
      JSON.parse(fs.readFileSync('./out/Periphery.sol/Periphery.json').toString()).abi,
      signer
    );

    const tx = await periphery.registerCore(targetNetwork.wormholeChainId, emitterBuffer, {
      gasLimit: 1000000,
    });
  }
  console.log(`Registered ${target} application on ${src}`);
}

export async function authenticate() {}

export async function requestLoan(chain: string, loanAmt: bigint, apr: bigint, tenor: bigint) {
  const srcNetwork = config.testnet[chain];
  let srcDeploymentInfo;
  try {
    srcDeploymentInfo = JSON.parse(fs.readFileSync(`./deployinfo/${chain}.deploy.json`).toString());
  } catch (e) {
    throw new Error(`${chain} is not deployed yet`);
  }

  const signer = new ethers.Wallet(process.env.PRIVATE_KEY).connect(
    new ethers.providers.JsonRpcProvider(srcNetwork.rpc)
  );

  const periphery = new ethers.Contract(
    srcDeploymentInfo.address,
    JSON.parse(fs.readFileSync('./out/Periphery.sol/Periphery.json').toString()).abi,
    signer
  );

  console.log('Requesting loan');
  const tx = await periphery.request(loanAmt, apr, tenor, {
    gasLimit: 1000000,
  });
  await tx.wait();
  console.log('Loan working');
  const seq = parseSequenceFromLogEth(tx, srcNetwork['bridgeAddress']);
  const emitterAddr = getEmitterAddressEth(srcDeploymentInfo['address']);

  await new Promise((r) => setTimeout(r, 5000)); // wait for the guardian to pick up the loan request

  console.log(
    'Searching for: ',
    `${config.wormhole.restAddress}/v1/signed_vaa/${srcNetwork.wormholeChainId}/${emitterAddr}/${seq}`
  );

  const vaaBytes = await (
    await fetch(`${config.wormhole.restAddress}/v1/signed_vaa/${srcNetwork.wormholeChainId}/${emitterAddr}/${seq}`)
  ).json();

  if (!vaaBytes['vaaBytes']) {
    throw new Error('VAA not found!');
  }

  if (!srcDeploymentInfo['vaas']) {
    srcDeploymentInfo['vaas'] = [vaaBytes['vaaBytes']];
  } else {
    srcDeploymentInfo['vaas'].push(vaaBytes['vaaBytes']);
  }
  fs.writeFileSync(`./deployinfo/${chain}.deploy.json`, JSON.stringify(srcDeploymentInfo, null, 4));
  return vaaBytes['vaaBytes'];
}
