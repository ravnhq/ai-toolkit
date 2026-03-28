import chalk from "chalk";

interface Quote {
  text: string;
  author: string;
}

export const almanacQuotes: Quote[] = [
  { text: "AI is the meta-solution to all other problems.", author: "Demis Hassabis" },
  { text: "Intelligence is a fundamental property of the universe that we are finally learning how to scale.", author: "Dario Amodei" },
  { text: "The hottest new programming language is English.", author: "Andrej Karpathy" },
  { text: "Software is eating the world, but AI is eating software.", author: "Jensen Huang" },
  { text: "AI is the new electricity.", author: "Andrew Ng" },
  { text: "The marginal cost of intelligence is headed toward zero.", author: "Sam Altman" },
  { text: "AI is a bicycle for the mind.", author: "Steve Jobs (Adapted)" },
  { text: "Stop coding the logic; start shaping the intent.", author: "Andrej Karpathy" },
  { text: "We are moving from the era of 'hand-crafted' rules to 'learned' intuition.", author: "Demis Hassabis" },
  { text: "AI will not replace managers, but managers who use AI will replace those who don't.", author: "Rob Thomas" },
  { text: "The real question is not whether machines think but whether men do.", author: "B.F. Skinner" },
  { text: "Intelligence is the most powerful technology in existence.", author: "Dario Amodei" },
  { text: "We should think of AI as an 'Exoskeleton for the Mind'.", author: "Garry Kasparov" },
  { text: "Success in creating AI would be the biggest event in human history.", author: "Stephen Hawking" },
  { text: "The goal isn't to build a 'god'; it's to build a reliable, steerable engine of reason.", author: "Dario Amodei" },
  { text: "AI is a mirror that reflects the best of human knowledge and amplifies it.", author: "Unknown" },
  { text: "The prompt is the new compiler.", author: "Andrej Karpathy" },
  { text: "Context is the fuel of intelligence.", author: "Anthropic Philosophy" },
  { text: "Precision in your prompt leads to precision in your production.", author: "Engineering Maxim" },
  { text: "Don't ask the AI to be right; ask it to think step-by-step.", author: "OpenAI Research" },
  { text: "A model is only as 'smart' as the data you provide in its context window.", author: "Developer Proverb" },
  { text: "Alignment isn't a feature; it's the foundation.", author: "Dario Amodei" },
  { text: "Interpretability is the bridge between a black box and a reliable tool.", author: "Anthropic Philosophy" },
  { text: "Build with 'Helpful, Honest, and Harmless' as your North Star.", author: "Dario Amodei" },
  { text: "The limit of the machine is the limit of the person using it.", author: "Satya Nadella" },
  { text: "Every token generated is a step toward solving a previously 'unsolvable' problem.", author: "Optimist Builder" },
  { text: "AI is the ultimate tool for science.", author: "Demis Hassabis" },
  { text: "We are essentially discovering the laws of intelligence, just as we once discovered the laws of physics.", author: "Sam Altman" },
  { text: "The goal of AI is to empower human beings to do what they do best: create, imagine, and connect.", author: "Fei-Fei Li" },
  { text: "The best way to predict the future is to invent it.", author: "Alan Kay" },
  { text: "We are scaling intelligence to the point where the only limit is your curiosity.", author: "Dario Amodei" },
  { text: "AI doesn't replace the architect; it gives the architect a billion workers to build the cathedral.", author: "Unknown" },
  { text: "We are moving from 'How do I do this?' to 'What should be done?'", author: "Future-Focused Dev" },
  { text: "The bottleneck of progress is no longer labor or compute; it is now the quality of our ideas.", author: "Modern Maxim" },
  { text: "Artificial intelligence is not a substitute for human intelligence; it is a tool to amplify it.", author: "Ginni Rometty" },
  { text: "AI is a tool of abundance in a world of scarcity.", author: "Sam Altman" },
  { text: "The most important thing about scaling is that models get qualitatively different.", author: "Dario Amodei" },
  { text: "Programming is no longer about telling a computer how to do something, but what you want achieved.", author: "Kevin Scott" },
  { text: "An LLM is a lossy compression of the entire internet's wisdom.", author: "Greg Brockman" },
  { text: "In an AI world, the most valuable skill is asking the right question.", author: "Satya Nadella" },
  { text: "We are teaching machines to understand us, so we can better understand ourselves.", author: "Demis Hassabis" },
  { text: "The true power of AI is its ability to find the needle of insight in the haystack of data.", author: "Unknown" },
  { text: "Scaling laws are the closest thing we have to a map of the future.", author: "Dario Amodei" },
  { text: "Don't build for the AI we have today; build for the AI we will have in six months.", author: "Founder Advice" },
  { text: "AI is the bridge between human imagination and digital reality.", author: "Unknown" },
  { text: "We are not just building software; we are building a more reliable partner for human intent.", author: "Anthropic Team" },
  { text: "Technology is not destiny; it is a choice.", author: "Fei-Fei Li" },
  { text: "AGI is the project of the century.", author: "Ilya Sutskever" },
  { text: "The future belongs to those who learn to dance with the machines.", author: "Unknown" },
  { text: "Focus on the work that only humans can do, and let the machines do the rest.", author: "Demis Hassabis" },
];

export function cmdPhrase(): void {
  const quote = almanacQuotes[Math.floor(Math.random() * almanacQuotes.length)];
  console.log();
  console.log(`  ${chalk.dim(`"${quote.text}"`)}`);
  console.log(`  ${chalk.dim(`\u2014 ${quote.author}`)}`);
  console.log();
}

export function cmdPoorCorvusAlmanac(): void {
  console.log();
  console.log(chalk.cyan("\uD83D\uDC26\u200D\u2B1B Poor Corvus Almanack: The 50 Maxims of Synthetic Intelligence"));
  console.log();
  almanacQuotes.forEach((quote, i) => {
    console.log(`  ${chalk.dim(`${i + 1}. "${quote.text}"`)}`);
    console.log(`     ${chalk.dim(`\u2014 ${quote.author}`)}`);
    console.log();
  });
}
