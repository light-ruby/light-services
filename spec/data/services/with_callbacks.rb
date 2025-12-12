# frozen_string_literal: true

# Base service with callbacks for testing
class WithCallbacks < ApplicationService
  # Steps
  step :letter_a
  step :letter_b

  # Track callback invocations
  output :callback_log, default: -> { [] }
  output :word, default: ""

  # Service callbacks using symbols
  before_service_run :log_before_service
  after_service_run :log_after_service
  on_service_success :log_service_success
  on_service_failure :log_service_failure

  # Step callbacks using symbols
  before_step_run :log_before_step
  after_step_run :log_after_step
  on_step_success :log_step_success
  on_step_failure :log_step_failure

  private

  def letter_a
    self.word += "a"
  end

  def letter_b
    self.word += "b"
  end

  def log_before_service(_service)
    callback_log << :before_service_run
  end

  def log_after_service(_service)
    callback_log << :after_service_run
  end

  def log_service_success(_service)
    callback_log << :on_service_success
  end

  def log_service_failure(_service)
    callback_log << :on_service_failure
  end

  def log_before_step(_service, step_name)
    callback_log << [:before_step_run, step_name]
  end

  def log_after_step(_service, step_name)
    callback_log << [:after_step_run, step_name]
  end

  def log_step_success(_service, step_name)
    callback_log << [:on_step_success, step_name]
  end

  def log_step_failure(_service, step_name, _exception)
    callback_log << [:on_step_failure, step_name]
  end
end

# Service with callbacks using procs
class WithCallbacksProc < ApplicationService
  output :callback_log, default: -> { [] }
  output :word, default: ""

  before_service_run do |_service|
    callback_log << :before_service_run_proc
  end

  after_service_run do |_service|
    callback_log << :after_service_run_proc
  end

  on_service_success do |_service|
    callback_log << :on_service_success_proc
  end

  before_step_run do |_service, step_name|
    callback_log << [:before_step_run_proc, step_name]
  end

  after_step_run do |_service, step_name|
    callback_log << [:after_step_run_proc, step_name]
  end

  step :do_work

  private

  def do_work
    self.word = "done"
  end
end

# Service with around callbacks
class WithAroundCallbacks < ApplicationService
  output :callback_log, default: -> { [] }
  output :word, default: ""

  around_service_run :wrap_service
  around_step_run :wrap_step

  step :do_work

  private

  def do_work
    self.word = "work"
    callback_log << :do_work
  end

  def wrap_service(_service)
    callback_log << :around_service_before
    yield
    callback_log << :around_service_after
  end

  def wrap_step(_service, step_name)
    callback_log << [:around_step_before, step_name]
    yield
    callback_log << [:around_step_after, step_name]
  end
end

# Service with around callbacks using procs
class WithAroundCallbacksProc < ApplicationService
  output :callback_log, default: -> { [] }
  output :word, default: ""

  around_service_run do |_service, block|
    callback_log << :around_service_before_proc
    block.call
    callback_log << :around_service_after_proc
  end

  around_step_run do |_service, step_name, block|
    callback_log << [:around_step_before_proc, step_name]
    block.call
    callback_log << [:around_step_after_proc, step_name]
  end

  step :do_work

  private

  def do_work
    self.word = "work"
    callback_log << :do_work
  end
end

# Service that fails
class WithCallbacksFailure < ApplicationService
  output :callback_log, default: -> { [] }

  before_service_run :log_before_service
  after_service_run :log_after_service
  on_service_success :log_service_success
  on_service_failure :log_service_failure

  step :add_error

  private

  def add_error
    errors.add(:base, "Something went wrong")
  end

  def log_before_service(_service)
    callback_log << :before_service_run
  end

  def log_after_service(_service)
    callback_log << :after_service_run
  end

  def log_service_success(_service)
    callback_log << :on_service_success
  end

  def log_service_failure(_service)
    callback_log << :on_service_failure
  end
end

# Service with step that raises exception
class WithCallbacksStepException < ApplicationService
  output :callback_log, default: -> { [] }

  before_step_run :log_before_step
  after_step_run :log_after_step
  on_step_success :log_step_success
  on_step_crash :log_step_crash

  step :raise_error

  private

  def raise_error
    raise StandardError, "Step exploded!"
  end

  def log_before_step(_service, step_name)
    callback_log << [:before_step_run, step_name]
  end

  def log_after_step(_service, step_name)
    callback_log << [:after_step_run, step_name]
  end

  def log_step_success(_service, step_name)
    callback_log << [:on_step_success, step_name]
  end

  def log_step_crash(_service, step_name, _exception)
    callback_log << [:on_step_crash, step_name]
  end
end

# Service with step that adds errors (for on_step_failure)
class WithCallbacksStepError < ApplicationService
  output :callback_log, default: -> { [] }

  before_step_run :log_before_step
  after_step_run :log_after_step
  on_step_success :log_step_success
  on_step_failure :log_step_failure

  step :add_error

  private

  def add_error
    errors.add(:base, "Step produced an error")
  end

  def log_before_step(_service, step_name)
    callback_log << [:before_step_run, step_name]
  end

  def log_after_step(_service, step_name)
    callback_log << [:after_step_run, step_name]
  end

  def log_step_success(_service, step_name)
    callback_log << [:on_step_success, step_name]
  end

  def log_step_failure(_service, step_name)
    callback_log << [:on_step_failure, step_name]
  end
end

# Service with multiple around callbacks (nested)
class WithMultipleAroundCallbacks < ApplicationService
  output :callback_log, default: -> { [] }

  around_service_run :outer_wrap
  around_service_run :inner_wrap

  step :do_work

  private

  def do_work
    callback_log << :do_work
  end

  def outer_wrap(_service)
    callback_log << :outer_before
    yield
    callback_log << :outer_after
  end

  def inner_wrap(_service)
    callback_log << :inner_before
    yield
    callback_log << :inner_after
  end
end

# Child service inheriting callbacks from parent
class WithCallbacksChild < WithCallbacks
  before_service_run :log_child_before_service

  step :letter_c

  private

  def letter_c
    self.word += "c"
  end

  def log_child_before_service(_service)
    callback_log << :child_before_service_run
  end
end

# Service that captures service instance to verify it's correct
class WithCallbacksInstanceVerification < ApplicationService
  output :captured_instances, default: -> { [] }
  output :captured_step_instances, default: -> { [] }
  output :result, default: ""

  before_service_run :capture_before_service
  after_service_run :capture_after_service
  on_service_success :capture_on_success

  before_step_run :capture_before_step
  after_step_run :capture_after_step
  on_step_success :capture_step_success

  around_service_run :capture_around_service
  around_step_run :capture_around_step

  step :do_work

  private

  def do_work
    self.result = "completed"
  end

  def capture_before_service(service)
    captured_instances << [:before_service_run, service.object_id, service.class.name]
  end

  def capture_after_service(service)
    captured_instances << [:after_service_run, service.object_id, service.class.name]
  end

  def capture_on_success(service)
    captured_instances << [:on_service_success, service.object_id, service.class.name]
  end

  def capture_around_service(service)
    captured_instances << [:around_service_before, service.object_id, service.class.name]
    yield
    captured_instances << [:around_service_after, service.object_id, service.class.name]
  end

  def capture_before_step(service, step_name)
    captured_step_instances << [:before_step_run, step_name, service.object_id, service.class.name]
  end

  def capture_after_step(service, step_name)
    captured_step_instances << [:after_step_run, step_name, service.object_id, service.class.name]
  end

  def capture_step_success(service, step_name)
    captured_step_instances << [:on_step_success, step_name, service.object_id, service.class.name]
  end

  def capture_around_step(service, step_name)
    captured_step_instances << [:around_step_before, step_name, service.object_id, service.class.name]
    yield
    captured_step_instances << [:around_step_after, step_name, service.object_id, service.class.name]
  end
end

# Grandchild service to test deep inheritance
class WithCallbacksGrandchild < WithCallbacksChild
  before_service_run :log_grandchild_before_service
  after_step_run :log_grandchild_after_step

  step :letter_d

  private

  def letter_d
    self.word += "d"
  end

  def log_grandchild_before_service(_service)
    callback_log << :grandchild_before_service_run
  end

  def log_grandchild_after_step(_service, step_name)
    callback_log << [:grandchild_after_step_run, step_name]
  end
end

# Parent service with all callback types for inheritance testing
class WithCallbacksParentComplete < ApplicationService
  output :callback_log, default: -> { [] }
  output :word, default: ""

  before_service_run :parent_before_service
  after_service_run :parent_after_service
  on_service_success :parent_on_success
  around_service_run :parent_around_service

  before_step_run :parent_before_step
  after_step_run :parent_after_step
  on_step_success :parent_step_success
  around_step_run :parent_around_step

  step :parent_work

  private

  def parent_work
    self.word += "parent"
  end

  def parent_before_service(_service)
    callback_log << :parent_before_service
  end

  def parent_after_service(_service)
    callback_log << :parent_after_service
  end

  def parent_on_success(_service)
    callback_log << :parent_on_success
  end

  def parent_around_service(_service)
    callback_log << :parent_around_service_before
    yield
    callback_log << :parent_around_service_after
  end

  def parent_before_step(_service, step_name)
    callback_log << [:parent_before_step, step_name]
  end

  def parent_after_step(_service, step_name)
    callback_log << [:parent_after_step, step_name]
  end

  def parent_step_success(_service, step_name)
    callback_log << [:parent_step_success, step_name]
  end

  def parent_around_step(_service, step_name)
    callback_log << [:parent_around_step_before, step_name]
    yield
    callback_log << [:parent_around_step_after, step_name]
  end
end

# Child that adds its own callbacks
class WithCallbacksChildComplete < WithCallbacksParentComplete
  before_service_run :child_before_service
  after_service_run :child_after_service
  on_service_success :child_on_success
  around_service_run :child_around_service

  before_step_run :child_before_step
  after_step_run :child_after_step
  on_step_success :child_step_success
  around_step_run :child_around_step

  step :child_work

  private

  def child_work
    self.word += "_child"
  end

  def child_before_service(_service)
    callback_log << :child_before_service
  end

  def child_after_service(_service)
    callback_log << :child_after_service
  end

  def child_on_success(_service)
    callback_log << :child_on_success
  end

  def child_around_service(_service)
    callback_log << :child_around_service_before
    yield
    callback_log << :child_around_service_after
  end

  def child_before_step(_service, step_name)
    callback_log << [:child_before_step, step_name]
  end

  def child_after_step(_service, step_name)
    callback_log << [:child_after_step, step_name]
  end

  def child_step_success(_service, step_name)
    callback_log << [:child_step_success, step_name]
  end

  def child_around_step(_service, step_name)
    callback_log << [:child_around_step_before, step_name]
    yield
    callback_log << [:child_around_step_after, step_name]
  end
end
