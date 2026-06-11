const data1 = [[{label: "toxic", score: 0.9}]];
const data2 = [{label: "toxic", score: 0.9}];

function getResults(data) {
  return Array.isArray(data?.[0]) ? data[0] : (Array.isArray(data) ? data : []);
}

console.log(getResults(data1));
console.log(getResults(data2));
