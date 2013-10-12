# page-object

[![Build Status](https://travis-ci.org/cheezy/page-object.png)](https://travis-ci.org/cheezy/page-object)


A simple gem that assists in creating flexible page objects for testing browser based applications. The goal is to facilitate creating abstraction layers in your tests to decouple the tests from the item they are testing and to provide a simple interface to the elements on a page. It works with both watir-webdriver and selenium-webdriver.

## Documentation

The project [wiki](https://github.com/cheezy/page-object/wiki/page-object) is the first place to go to learn about how to use page-object.

The rdocs for this project can be found at [rubydoc.info](http://rubydoc.info/gems/page-object/frames).

To see the changes from release to release please look at the [ChangeLog](https://raw.github.com/cheezy/page-object/master/ChangeLog)

To read about the motivation for this gem please read this [blog entry](http://www.cheezyworld.com/2010/11/19/ui-tests-introducing-a-simple-dsl/)

There is a book that describes in detail how to use this gem and others to create a complete view of testing web and other types of applications.  The book is named [Cucumber & Cheese](http://leanpub.com/cucumber_and_cheese)

## Support

If you need help using the page-object gem please ask your questions on [Stack Overflow](http://stackoverflow.com).  Please be sure to use the [page-object-gem](http://stackoverflow.com/questions/tagged/page-object-gem) tag.  If you wish to report an issue or request a new feature use the [github issue tracking page](http://github.com/cheezy/page-object/issues).

## Basic Usage

### Defining your page object

You define a new page object by including the PageObject module:

````ruby
class LoginPage
  include PageObject
end
````
    
When you include this module numerous methods are added to your class that allow you to easily define your page. For the login page you might add the following:

````ruby
class LoginPage
  include PageObject
      
  text_field(:username, :id => 'username')
  text_field(:password, :id => 'password')
  button(:login, :id => 'login')
end
````

Calling the _text_field_ and _button_ methods adds several methods to our page object that allow us to interact with the items on the page. To login using this page we could simply write the following code:

````ruby
login_page.username = 'cheezy'
login_page.password = 'secret'
login_page.login
````
    
Another approach might be to create higher level methods on our page object that hide the implementation details even further. Our page object might look like this:

````ruby
class LoginPage
  include PageObject
  
  text_field(:username, :id => 'username')
  text_field(:password, :id => 'password')
  button(:login, :id => 'login')
  
  def login_with(username, password)
    self.username = username
    self.password = password
    login
  end
end
````

and your usage of the page would become:

````ruby
login_page.login_with 'cheezy', 'secret'
````

### Creating your page object
page-object supports both [watir-webdriver](https://github.com/jarib/watir-webdriver) and [selenium-webdriver](http://seleniumhq.org/docs/03_webdriver.html). The one used will be determined by which driver you pass into the constructor of your page object. The page object can be create like this:

````ruby
browser = Watir::Browser.new :firefox
my_page_object = MyPageObject.new(browser)
````

or

````ruby
browser = Selenium::WebDriver.for :firefox
my_page_object = MyPageObject.new(browser)
````

### Nested Dynamic Elements
For pages that are dynamic, it's hard to define static page accessors.

For example: A quiz creation page can create one quiz with any number of questions. Using Rails nested attributes, you can have an "Add one more question" button that adds one more question to the quiz dynamically.
Even if each question only have a few answers. With many questions, it can get really
complicated real quick to keep track of all the question fields and their answers fields. 

You can use the DynamicElementAccessor module to help you navigate through this. 

````html
<div class='questions'>
  <label>Question</label>
  <input id='question' type='text'>
  <label>Answers</label>
  <input id='answer1' type='text'>
  <input id='answer2' type='text'>
</div>
<button>Add one more question</button>
````
First define class for one of your dynamic objects. In this case a single question.

````ruby
class QuizQuestion
  include PageObject::DynamicElementAccessor

  # definte accessors as you normally with page objects
  # you can create another 'Answer' class with this module mixed in
  # if you want arbitrary number of answers, it can be nested.  
  text_field :question,    :css => "input[id$=question]"
  text_field :answer1,     :css => "input[id$=answer1]"
  text_field :answer2,     :css => "input[id$=answer2]"
end
````
Inside your QuizCreator page object, define a getter that gets the all the questions.
If new question gets added as a result of some dynamic actions on the page simply call get_questions again to get the new set of questions. 

````ruby
class QuizCreator
  include PageObject
  # ...
  def get_questions
    questions = []

	# get the containers that groups your sub elements
	
    elements = self.div_elements(:css => "div.question")
	
	# create a QuizQuestion container for each one of them
    elements.each do |element|
      if element.visible?
        questions << QuizQuestion.new(
          :page_object    => self,
          :parent_element => element
        )
      end
    end
    questions
  end
  # ... rest of your class
end   
````

After you get the list of questions back, you can operate on each question object as if they are page object themselves.
````ruby
questions = QuizCreator.new(...).get_questions
questions[0].question ="123"
questions[0].answer1  ="234"
questions[1].question ="abc"
questions[1].answer2  ="efg"
````

## Known Issues

See [http://github.com/cheezy/page-object/issues](http://github.com/cheezy/page-object/issues)

## Contribute
 
* Fork the project.
* Test drive your feature addition or bug fix. Adding specs is important and I will not accept a pull request that does not have tests.
* Make sure you describe your new feature with a cucumber scenario.
* Make sure you provide RDoc comments for any new public method you add. Remember, others will be using this gem.
* Commit, do not mess with Rakefile, version, or ChangeLog.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2011-2012 Jeffrey S. Morgan. See LICENSE for details.
