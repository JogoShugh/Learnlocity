class VocabWord
    constructor: (@word, @definition, @exampleSentence='') ->

class VocabDictionary
    _words: []

    allWords: ->
        return @_words

    importWords: (words) ->
        _words = []
        for word in words
            @_words.push new VocabWord(word.word, word.definition, word.exampleSentence)

    addWord: (word, definition, exampleSentence='') ->
        @_words.push(new VocabWord(word, definition, exampleSentence))

    getWord: (index) ->
        return @_words[index]

    getWordByName: (word) ->
        """
        var dictionaryWord = Enumerable.from(this._words).firstOrDefault(function (w) { return w.word == word; });
        return dictionaryWord;
        """
    getRandomWord: ->
        word = @_words[Math.floor(Math.random() * @_words.length)]

    wordCount: ->
        return @_words.length

AgileDictionary = new VocabDictionary()

AgileDictionary.addWord 'Aggregate', 'A cluster of associated objects that are treated as a unit for the purpose of data changes. External references are restricted to one of its members, designated as the root. A set of consistency rules applies within its boundaries.'

AgileDictionary.addWord 'Analysis Patterns', 'A group of concepts that represents a common construction in business modeling. It may be relevant to only one domain or may span many domains.'
AgileDictionary.addWord 'Assertion', 'A statement of the correct state of a program at some point, independent of how it does it. Typically, it specifies the result of an operation or an invariant of a design element.'

AgileDictionary.addWord 'Bounded Context', 'The delimited applicability of a particular model. It gives team members a clear and shared understanding of what has to be consistent and what can develop independently.'

AgileDictionary.addWord 'Client', 'A program element that is calling the element under design, using its capabilities.'

AgileDictionary.addWord 'Cohesion', 'Logical agreement and dependence.'

AgileDictionary.addWord 'Command', 'An operation that effects some change to the system (for example, setting a variable). An operation that intentionally creates a side effect.'

AgileDictionary.addWord 'Context', 'The setting in which a word or statement appears that determines its meaning.'

AgileDictionary.addWord 'Conceptual Contour', 'An underlying consistency of the domain itself, which, if reflected in a model, can help the design accommodate change more naturally.'

AgileDictionary.addWord 'Context Map', 'A representation of how different Bounded Contexts are involved in a project and the actual relationships between them and their models.'

AgileDictionary.addWord 'Core Domain', 'The distinctive part of the model, central to user goals, that differentiates the application and makes it valuable.'

AgileDictionary.addWord 'Declarative Design', 'A form of programming in which a precise description of properties actually controls the software. An executable specification.'

AgileDictionary.addWord 'Deep Model', 'An incisive expression of the primary concerns of the domain experts and their most relevant knowledge. This sloughs off superficial aspects of the domain and naive interpretations.'

AgileDictionary.addWord 'Design Pattern', 'A description of communicating objects and classes that are customized to solve a general problem in a particular context.'

AgileDictionary.addWord 'Distillation', 'A process of separating the components of a mixture to extract the essence in a form that makes it more valuable and useful. In software design, the abstraction of key aspects in a model, or the partitioning of a larger system to bring the Core Domain to the fore.'

AgileDictionary.addWord 'Domain', 'A sphere of knowledge, influence, or activity.'

AgileDictionary.addWord 'Domain-Driven Design', 'An approach to software development that suggests that 1) For most software projects, the primary focus should be on the business and logic; and (2) Complex designs should be based on a model.'

AgileDictionary.addWord 'Domain Expert', 'A member of a software project whose field is the business side of the application, rather than software development. Not just any user of the software, this person has deep knowledge of the subject.'

AgileDictionary.addWord 'Domain Layer', 'That portion of the design and implementation responsible for business logic within a layered architecture. It is where the software expression of the model lives.'

AgileDictionary.addWord 'Entity', 'An object fundamentally defined not by its attributes, but by a thread of continuity and identity.'

AgileDictionary.addWord 'Factory', 'A mechanism for encapsulating complex creation logic and abstracting the type of a created object for the sake of a client.'

AgileDictionary.addWord 'Function', 'An operation that computes and returns a result without observable side effects.'

AgileDictionary.addWord 'Immutable', 'The property of never changing observable state after creation.'

AgileDictionary.addWord 'Implicit concept', 'Something that is necessary to understand the meaning of a model or design but is never mentioned.'

AgileDictionary.addWord 'Intention-Revealing Interface', 'A design in which the names of classes, methods, and other elements convey both the original author\'s purpose in creating them and their value to a client developer.'

AgileDictionary.addWord 'Invariant', 'An assertion about some design element that must be true at all times, except during specifically transient situations such as the middle of the execution of a method, or the middle of an uncommitted database transaction.'

AgileDictionary.addWord 'Iteration', 'A process in which a program is repeatedly improved in small steps. Also, one of those steps.'

AgileDictionary.addWord 'Large-Scale Structure', 'A set of high-level concepts, rules, or both that establishes a pattern of design for an entire system. A language that allows the system to be discussed and understood in broad strokes.'

AgileDictionary.addWord 'Layered Architecture', 'A technique for separating the concerns of a software system, isolating a domain, among other things.'

AgileDictionary.addWord 'Life Cycle', 'A sequence of states an object can take on between creation and deletion, typically with constraints to ensure integrity when changing from one state to another.'

AgileDictionary.addWord 'Model', 'A system of abstractions that describes selected aspects of a domain and can be used to solve problems related to that domain.'

AgileDictionary.addWord 'Model-Driven Design', 'A design in which some subset of software elements corresponds closely to elements of a model. Also, a process of codeveloping a model and an implementation that stay aligned with each other.'

AgileDictionary.addWord 'Modeling Paradigm', 'A particular style of carving out concepts in a domain, combined with tools to create software analogs of those concepts (for example, object-oriented programming and logic programming).'

AgileDictionary.addWord 'Repository', 'A mechanism for encapsulating storage, retrieval, and search behavior which emulates a collection of objects.'

AgileDictionary.addWord 'Responsibility', 'An obligation to perform a task or know information.'

AgileDictionary.addWord 'Service', 'An operation offered as an interface that stands alone in the model, with no encapsulated state.'

AgileDictionary.addWord 'Side Effect', 'Any observable change of state resulting from an operation, whether intentional or not, even a deliberate update.'

AgileDictionary.addWord 'Standalone Class', 'Something that can be understood and tested without reference to any others, except system primitives and basic libraries.'

AgileDictionary.addWord 'Stateless', 'The property of a design element that allows a client to use any of its operations without regard to the element\’s history. It may use information that is accessible globally and may even change that global information but holds no private information that affects its behavior.'

AgileDictionary.addWord 'Strategic Design', 'Modeling and design decisions that apply to large parts of the system. Such decisions affect the entire project and have to be decided at team level.'

AgileDictionary.addWord 'Supple Design', 'A design that puts the power inherent in a deep model into the hands of a client developer to make clear, flexible expressions that give expected results robustly. Equally important, it leverages that same deep model to make the design itself easy for the implementer to mold and reshape to accommodate new insight.'

AgileDictionary.addWord 'Ubiquitous Language', 'A language structured around the domain model and used by all team members to connect all the activities of the team with the software.'

AgileDictionary.addWord 'Unification', 'The internal consistency of a model such that each term is unambiguous and no rules contradict.'

AgileDictionary.addWord 'Test-Driven Development', 'A lightweight programming methodology that emphasizes fast, incremental development and especially writing code that specifies the outward client interface before writing the implementation code.'

AgileDictionary.addWord 'Value Object', 'An object that describes some characteristic or attribute but carries no concept of identity.'

AgileDictionary.addWord 'Whole Value', 'An object that models a single, complete concept.'

exports.Dictionary = AgileDictionary