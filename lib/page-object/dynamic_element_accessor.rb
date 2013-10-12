module PageObject
  # Dynamic Element Accessor is a module that behaves similarly to the 
  # page-object module. This module is designed to be mixed into classes that
  # need to operate on a group of dynamically generated sub elements of a page. 
  # 
  # For example: A quiz creation page can create one quiz with many 
  # number of questions. With rails nested attributes, you can have
  # an "Add one more question" button that adds one more question to the quiz.
  # dynamically.
  # Let's say each question have a few multiple guess answers. It can get really
  # complicated really quick to keep track of all the question fields and their
  # answers fields. 
  # 
  # example usage:
  #
  # Let's say your webpage looks like this
  # <div class='questions'>
  #   <label>Question</label>
  #   <input id='question' type='text'>
  #   <label>Answers</label>
  #   <input id='answer1' type='text'>
  #   <input id='answer2' type='text'>
  # </div>
  # ...
  # <button>Add one more question</button>
  #
  # # First define class for one of your dynamic objects in this case a single question
  #
  # class QuizQuestion
  #   include PageObject::DynamicElementAccessor
  # 
  #   # definte accessors as you normally with page objects
  #   # you can create another Answer class with this module mixed in
  #   # if you want arbitrary number of answers, it can be nested.  
  #   text_field :question,    :css => "input[id$=question]"
  #   text_field :answer1,     :css => "input[id$=answer1]"
  #   text_field :answer2,     :css => "input[id$=answer2]"
  # end
  #
  # # Inside your QuizCreator page object, define a getter that gets the all the questions.
  # # If new question gets added as a result of some dynamic actions on the page
  # # simply call get_questions again to get the new set of questions. 
  # class QuizCreator
  #   include PageObject
  #
  #   def get_questions
  #     questions = []
  #     elements = self.div_elements(:css => "div.question")
  #     elements.each do |element|
  #       if element.visible?
  #         questions << QuizQuestion.new(
  #           :page_object    => self,
  #           :parent_element => element
  #         )
  #       end
  #     end
  #     questions
  #   end
  # end   
  # 
  # After you get the list of questions back, you can operate on each question
  # object as if their mini page object themselves.
  #  questions = QuizCreator.new(...).get_questions
  #  questions[0].question ="123"
  #  questions[0].answer1  ="234"
  #  questions[1].question ="abc"
  #  questions[1].answer2  ="efg"
  # 
  module DynamicElementAccessor
    
    def initialize(options)
      self.page_object = options[:page_object]
      self.parent_element = options[:parent_element]
      
      raise "page object missing" if !self.page_object
      raise "parent element missing" if !self.parent_element
      after_initialize(options) if self.respond_to?(:after_initialize)
    end
    
    def self.included(base)
      base.extend ClassMethods
      attr_accessor :page_object, :parent_element
    end
    
    module ClassMethods #:nodoc:
      def accessor_selectors #:nodoc:
        @accessor_selectors ||= {}
        @accessor_selectors
      end

      # text field generators
    
      def text_field(name, selector)
        accessor_selectors[name.to_sym] = selector.clone

        value_getters(name, :text_field)
        value_setters(name, :text_field)
        standard_methods(name, :text_field)
      end

      # text area generators
    
      def text_area(name, selector)
        accessor_selectors[name.to_sym] = selector.clone

        value_getters(name, :text_area)
        value_setters(name, :text_area)
        standard_methods(name, :text_area)
      end

      # hidden field generators
    
      def hidden_field(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
        value_getters(name, :hidden_field)
      
        standard_methods(name, :hidden_field)
      end

      # div generators
    
      def div(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
      
        text_getters(name, :div)
        standard_methods(name, :div)
      end

      # label generators
    
      def label(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
  
        text_getters(name, :label)
        standard_methods(name, :label)
      end
      
      # file field generators
      
      def file_field(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
  
        value_setters(name, :file_field)
        standard_methods(name, :file_field)
      end
      
      # button generators
    
      def button(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
        define_method(name) do
          element = self.get_child_element(name, :button)
          element.click
        end
      
        standard_methods(name, :button)
      end

      # checkbox generators
    
      def checkbox(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
        define_method name do
          element = self.get_child_element(name, :checkbox)
          element.checked?
        end
      
        define_method "#{name}=" do |value|
          element = self.get_child_element(name, :checkbox)
          value ?  element.check : element.uncheck 
        end

        define_method("check_#{name}") do
          self.send("#{name}=", true)
        end

        define_method("uncheck_#{name}") do
          self.send("#{name}=", false)
        end

        define_method("#{name}_checked?") do
          self.send("#{name}")
        end

        standard_methods(name, :check_box)
      end

      # select list generators

      def select_list(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
        define_method(name) do
          element = self.get_child_element(name, :select_list)
          element.value
        end
        define_method("#{name}=") do |value|
          element = self.get_child_element(name, :select_list)
          element.select(value)
        end
      
        define_method("#{name}_options") do
          element = self.get_child_element(name, :select_list)
          element.options.collect(&:text)
        end

        standard_methods(name, :select_list)
      end

      # link generators
    
      def link(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
        define_method(name) do
          element = self.get_child_element(name, :link)
          element.click
        end
      
        standard_methods(name, :link)
      end
    
      # image generators
    
      # def image(name, selector)
      #   accessor_selectors[name.to_sym] = selector.clone
      #   standard_methods(name, :image)
      # end

      # span generators
    
      def span(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
        text_getters(name, :span)
        standard_methods(name, :span)
      end
      
      # form
      
      # def form(name, selector)
      #   accessor_selectors[name.to_sym] = selector.clone
      #   text_getters(name, :form) # why do you need get text getters?
      #   standard_methods(name, :form)
      # end

      #unordered list generators
      def unordered_list(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
        standard_methods(name, :unordered_list)
      end
          
      # table generators
      def table(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
        standard_methods(name, :table)
      end

      # cell generators
    
      def cell(name, selector)
        accessor_selectors[name.to_sym] = selector.clone
        text_getters(name, :cell)
        standard_methods(name, :cell)
      end

      # internal method generators
    
      def text_getters(name, type)  #:nodoc:
        define_method name do
          element = self.get_child_element(name, type)
          element.text
        end
      end

      def value_setters(name, type) #:nodoc:
        define_method "#{name}=" do |value|
          element = self.get_child_element(name, type)
          element.value = value.to_s
        end
      end
    
      def value_getters(name, type) #:nodoc:
        define_method name do
          element = self.get_child_element(name, type)
          element.value
        end
      end

      # # generate standard element locators for most things
      # # generats methods like
      # # def h1(name, selector)
      # # end
      # # stores the name to selector in hash and further generates 
      # # <name>_element and <name>?
      # 
      # (PageObject::LocatorGenerator::BASIC_ELEMENTS + 
      #   PageObject::LocatorGenerator::ADVANCED_ELEMENTS).each do |tag|
      #   define_method("#{tag}") do |name, selector|
      #     accessor_selectors[name.to_sym] = selector.clone
      #     standard_methods(name, tag)
      #   end
      # end
      

      def standard_methods(name, type) #:nodoc:
        define_method("#{name}_element") do
          self.get_child_element(name, type)
        end
        define_method("#{name}?") do
          self.send("#{name}_element").exists?
        end
      end
    end
    
    # internal use for accessing statically defined child elements
    def get_child_element(name, element_type)
      selector = self.class.accessor_selectors[name]
      raise "No selector for element #{name}" if selector == nil
   
      self.from_parent_element(element_type, selector)
    end

    # for sub classes to use to fetch additional fields from parent fields
    def from_parent_element(element_type, selector)
      element = self.parent_element.send(
        "#{element_type.to_s}_element", selector)
      element
    end
    
    # settable fields defined in the class that included this module
    def settable_fields
      self.class.accessor_selectors.keys.select do|key|
        self.respond_to?("#{key.to_s}=")
      end
    end
    
  end
end

