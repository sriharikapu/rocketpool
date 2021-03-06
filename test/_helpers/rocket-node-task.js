// Dependencies
import { RocketNodeTasks, RocketStorage, TestNodeTask } from '../_lib/artifacts';


// Create a test node task contract
export async function createTestNodeTaskContract({name, owner}) {

    // Get storage
    let rocketStorage = await RocketStorage.deployed();

    // Create and return test node task contract
    let nodeTask = await TestNodeTask.new(rocketStorage.address, name, {gas: 5000000, gasPrice: 10000000000, from: owner});
    return nodeTask;

}


// Add a node task
export async function addNodeTask({taskAddress, owner}) {
    let rocketNodeTasks = await RocketNodeTasks.deployed();
    await rocketNodeTasks.add(taskAddress, {from: owner, gas: 500000});
}


// Remove a node task
export async function removeNodeTask({taskAddress, owner}) {
    let rocketNodeTasks = await RocketNodeTasks.deployed();
    await rocketNodeTasks.remove(taskAddress, {from: owner, gas: 500000});
}


// Update a node task
export async function updateNodeTask({oldAddress, newAddress, owner}) {
    let rocketNodeTasks = await RocketNodeTasks.deployed();
    await rocketNodeTasks.update(oldAddress, newAddress, {from: owner, gas: 500000});
}

