import React from 'react';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';

const faqData = [
  {
    question: 'How much does the app cost?',
    answer:
      'TrakkyFood is completely free for users! You can download it and start searching for food trucks without any subscription fees.',
  },
  {
    question: 'Is the location tracking really live?',
    answer:
      'Yes! We provide real-time GPS tracking for registered food trucks, so you see their exact spot as they move or park.',
  },
  {
    question: 'Can I see the menus before going?',
    answer:
      'Absolutely. Each truck profile includes a full digital menu with prices and photos to help you decide.',
  },
  {
    question: 'How do I register my own food truck?',
    answer:
      'You can contact our support team through the "For Business" link in the footer or directly from the app\'s settings.',
  },
];

export default function FAQ() {
  return (
    <section className="py-24 bg-off-white">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <h3 className="text-4xl font-extrabold text-center mb-16">Frequently Asked Questions</h3>
        <Accordion type="single" collapsible className="space-y-4">
          {faqData.map((item, index) => (
            <AccordionItem
              key={index}
              value={`item-${index}`}
              className="bg-white rounded-2xl border border-slate-100 shadow-sm px-6"
            >
              <AccordionTrigger className="font-bold text-lg py-6 hover:no-underline">
                {item.question}
              </AccordionTrigger>
              <AccordionContent className="text-slate-600 pb-6">{item.answer}</AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </div>
    </section>
  );
}
