window.onload = function() {
  let elements = document.querySelectorAll('li');

  for (let i = 0; i < elements.length; i++) {
    if (elements[i].innerText.includes('der')) {
      elements[i].classList.add('blue-text');
    } else if (elements[i].innerText.includes('die')) {
      elements[i].classList.add('red-text');
    } else if (elements[i].innerText.includes('das')) {
      elements[i].classList.add('green-text');
    }
  }
};
