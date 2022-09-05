window.onload = function() {
  let elements = document.querySelectorAll('li');

  for (let i = 0; i < elements.length; i++) {
    if (elements[i].innerText.slice(0, 3) === 'der') {
      elements[i].classList.add('blue-text');
    } else if (elements[i].innerText.slice(0, 3) === 'die') {
      elements[i].classList.add('red-text');
    } else if (elements[i].innerText.slice(0, 3) === 'das') {
      elements[i].classList.add('green-text');
    }
  }
};
