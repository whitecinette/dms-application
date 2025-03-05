String formatIndianNumber(num number) {
  if (number >= 10000000) {
    return "${(number / 10000000).toStringAsFixed(2)}Cr"; // Crore
  } else if (number >= 100000) {
    return "${(number / 100000).toStringAsFixed(2)}L"; // Lakh
  } else if (number >= 1000) {
    return "${(number / 1000).toStringAsFixed(2)}K"; // Thousand
  } else {
    return number.toString(); // Keep it as is if less than 1000
  }
}
