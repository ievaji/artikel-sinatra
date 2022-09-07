# ARTIKEL

Is it 'der Band', 'das Band' or 'die Band'? Use Artikel to qickly answer that question!

The idea for this project arose out of a daily need to look up the Artikel for German nouns. I made it for learning purposes and the result is meant for anyone who needs help with this part of German grammar. It is strictly non-commercial, in short. Long live free knowledge!

Artikel uses Wiktionary for lookup and links to it for further details. 

It can be tested here: https://artikel-sinatra.herokuapp.com/



## How it works

- Classes
  - [Word](https://github.com/ievaji/artikel-sinatra/edit/master/README.md#word)
  - [Cleaner](https://github.com/ievaji/artikel-sinatra/edit/master/README.md#cleaner)
  - [Finder](https://github.com/ievaji/artikel-sinatra/edit/master/README.md#finder)
    - Main Methods
- [Results explained](https://github.com/ievaji/artikel-sinatra/edit/master/README.md#results-explained)

## Word

Word is essentially the central model of this app. It is instantiated with partial information about itself and then calls on Finder to get the missing part – which is what the user came for, too.

Currently all words are assumed to be nouns and are capitalized accordingly. However, the Word class can be subclassed into Verb and Noun, should the project ever be expanded.


## Cleaner

Cleaner is a helper class used by both Word and Finder (mostly the latter). All of its methods are class methods to skip creating an instance.


## Finder

Finder is the main working class. It is instantiated with a string (a Word instance) and returns an array of results.

During instantiation it converts the string to Unicode, sends a request, processes the response and saves it as an instance variable for further reference in its methods. The string itself is kept only for quick exception handling (see the example of “Oder” below).

###### #find_artikel 
Finder’s main method checks, if the word has several meanings and then processes the response accordingly I two different ways. This kind of binary branching logic is followed throughout the Finder class.

If the word has several meanings, the response contains a table of contents. In that case it is the element processed. If there’s only one meaning, there will be no table of contents, and headlines are processed instead.

This simplifies debugging, since one can always identify the branch one is on by simply looking at the data source.

###### #process_content_table 
The first scenario – several meanings.

Here again the path divides in two, and the position of toponyms or geographical names in the table of contents is the deciding factor.

If the first entry in the table of contents is already a toponym, the word has no other meanings, since any other meaning would supersede it in importance. In this case toponyms are processed, and their grammar extracted.

The only exception is the word “Oder” who’s geographical meaning is important and hence must be included in the results. It is currently handled as the only exception.

If, however, the first entry is not a toponym, geographical names are excluded from results since their grammar is of no interest and would only create confusion.

The same logic applies to plural: If the first meaning is plural, it is a plural noun. Results are adjusted accordingly, and the method returns them without processing the data any further.

When toponyms are excluded, an additional filter for regionalisms is applied. It checks the length of each headline in the table of contents. If these strings don’t contain additional information about meaning, which would be another word, the cases listed are merely regional grammatical variations. These, again, are of no interest to the user, since they fall outside standard German.

###### #process_page_content
The second path – if there is no table of contents, the word has only one meaning.

This method follows a similar logic of dividing the process into two distinct paths. The deciding factor here is the presence of a longer explanatory text. If that text includes certain keywords, that means we’re dealing with an exception (regional spelling or a declinated form). In this case no Artikel will be found, instead the user will receive the information about the exception at hand. They can then use it to perform a new search.

If, however, an exception case cannot be detected, the program will proceed to extract genus information and then convert it into an Artikel and return it to Word. During the extraction process some additional filtering is done to exclude irrelevant information.

## Results explained

Word assigns the value of Finder’s @results array to its own instance variable @artikel, which is then accessed by the View.

There are a few cases to account for:
1)	The array contains ‘Not found’ or is empty.
2)	The array contains a long string.
3)	The array contains one or several Artikeln associated with the given word.

Explanation:
1)	The response was 404 or the results didn’t pass the filters.
2)	The page contained information relevant to the user, though no Artikel could be extracted.
3)	Artikeln were found and are ready to be displayed.
