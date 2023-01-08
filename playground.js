async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function* generate() {
  // let i = 0;
  // while (true) {
  //   await sleep(1000);
  //   yield i++;
  // }
  await sleep(1000);
  console.log('first');
  yield 1;
  console.log('second');
}

let iterator = generate();

console.log(iterator);
console.log(iterator.next().then(console.log));
console.log(iterator.next().then(console.log));
