$('.workouts.new, .workouts.edit').ready ->
  window.codeworkout ?= {}
  window.codeworkout.removed_exercises = []
  window.codeworkout.removed_offerings = []
  window.codeworkout.removed_extensions = []

  sortable = $('#ex-list').sortable
    handle: '.handle'

  init_templates()
  init_datepickers()
  validate_workout_name()

  $('#wo-name').change ->
    validate_workout_name()

  $('.search-results').on 'click', '.add-ex', ->
    $('.empty-msg').css 'display', 'none'
    $('#ex-list').css 'display', 'block'
    ex_name = $(this).data('ex-name')
    ex_id = $(this).data('ex-id')
    data =
      name: ex_name
      id: ex_id
      points: 0
    template = Mustache.render($(window.codeworkout.exercise_template).filter('#exercise-template').html(), data)
    $('#ex-list').append(template)

  $('#add-offering').on 'click', ->
    $('#workout-offering-fields tbody').append($('#add-offering-form tbody').html())
    init_datepickers()

  $('#workout-offering-fields').on 'click', '.delete-offering', ->
    row = $(this).closest 'tr'
    workout_offering_id = row.data 'id'
    course_offering_id = row.find('.coff-select').val()
    delete_confirmed = false
    if course_offering_id != ''
      delete_confirmed = remove_extensions_if_any parseInt(course_offering_id)

    if delete_confirmed
      if workout_offering_id? && workout_offering_id != ''
        window.codeworkout.removed_offerings.push workout_offering_id
      row.remove()

  $('#workout-offering-fields').on 'change', '.coff-select', ->
    val = $(this).val()
    row = $(this).closest 'tr'

    if val != ''
      row.attr('id', 'off-' + val)
      row.find('.add-extension').addClass 'btn-primary'
      row.find('.add-extension').prop 'disabled', false
    else
      row.find('.add-extension').removeClass 'btn-primary'
      row.find('.add-extension').prop 'disabled', true

  $('#workout-offering-fields').on 'click', '.add-extension', ->
    course_offering = $(this).closest('tr').find('.coff-select option:selected').text()
    course_offering_id = $(this).closest('tr').find('.coff-select').val()
    clear_student_search()
    $('#extension-modal').data('course-offering', { id: course_offering_id, display: course_offering } )
    $('#extension-modal #modal-header').append 'Searching for students from <u>' + course_offering + '</u>'
    $('#btn-student-search').click ->
      search_students(course_offering_id)
    $('#terms').keydown (e) ->
      if e.keyCode == 13
        search_students(course_offering_id)

  $('#results').on 'click', 'a', ->
    course_offering = $('#extension-modal').data('course-offering')
    student =
      id: $(this).data('student-id')
      display: $(this).text()
    data =
      course_offering_id: course_offering.id
      course_offering_display: course_offering.display
      student_display: student.display
      student_id: student.id
    template = Mustache.render($(window.codeworkout.student_extension_template).filter('#extension-template').html(), data)
    $('#student-extension-fields tbody').append(template)
    $('#extension-modal').modal('hide')
    $('#extensions').css 'display', 'block'
    init_datepickers()

  $(document).on 'click', '.delete-extension', ->
    $(this).closest('tr').remove()

  $('#ex-list').on 'click', '.delete-ex', ->
    ex_row = $(this).closest 'li'
    ex_workout_id = ex_row.data 'exercise-workout-id'
    if ex_workout_id? && ex_workout_id != ''
      window.codeworkout.removed_exercises.push ex_workout_id
    ex_row.remove()
    exs = $('#ex-list li').length
    if exs == 0
      $('.empty-msg').css 'display', 'block'
      $('#ex-list').css 'display', 'none'

  $('#btn-submit-wo').click ->
    handle_submit()

remove_extensions_if_any = (course_offering_id) ->
  extensions = $('#student-extension-fields tbody').find 'tr'
  to_remove = []
  for extension in extensions
    do (extension) ->
      offering = $(extension).data 'course-offering-id'
      if offering == course_offering_id
        to_remove.push $(extension).index()

  if to_remove.length > 0
    if confirm 'Removing this workout offering will also remove ' + to_remove.length + ' student extension(s).'
      for index in to_remove
        do (index) ->
          id = $($(extensions)[index]).data 'id'
          if id? && id != ''
            window.codeworkout.removed_extensions.push id
          $(extensions)[index].remove()
      return true
    else
      return false
  else
    return true

init_templates = ->
  $.get '/assets/exercise.mustache.html', (template, textStatus, jqXHr) ->
    window.codeworkout.exercise_template = template
    if $('body').is '.workouts.edit'
      init_exercises()
  $.get '/assets/student_extension.mustache.html', (template, textStatus, jqXHr) ->
    window.codeworkout.student_extension_template = template
    if $('body').is '.workouts.edit'
      init_student_extensions()

clear_student_search = ->
  $('#extension-modal #modal-header').empty()
  $('#msg').empty()
  $('#results').empty()
  $('#terms').val('')

search_students = (course_offering_id) ->
  $.ajax
    url: '/course_offerings/' + course_offering_id + '/search_students'
    type: 'get'
    data: { terms: $('#terms').val() }
    cache: true
    dataType: 'script'
    success: (data) ->
      # init_datepickers()

validate_workout_name = ->
  can_update = $('#workout-offering-fields').data 'can-update'
  name_field = $('#wo-name')
  if can_update == false
    if name_field.val() == name_field.data 'old-name'
      $('#clone-msg').css 'display', 'block'
      return false
    else
      $('#clone-msg').css 'display', 'none'
      return true

  return true

init_student_extensions = ->
  student_extensions = $('#extensions').data 'student-extensions'
  if student_extensions
    $('#extensions').css 'display', 'block'
    for extension in student_extensions
      do (extension) ->
        data =
          id: extension.id
          course_offering_id: extension.course_offering_id
          course_offering_display: extension.course_offering_display
          student_id: extension.student_id
          student_display: extension.student_display
          time_limit: extension.time_limit
          opening_date: extension.opening_date
          soft_deadline: extension.soft_deadline
          hard_deadline: extension.hard_deadline
        template =
            $(Mustache.render($(window.codeworkout.student_extension_template).filter('#extension-template').html(), data))
        $('#student-extension-fields tbody').append template
        init_row_datepickers template

init_exercises = ->
  exercises = $('#ex-list').data 'exercises'
  if exercises
    for exercise in exercises
      do (exercise) ->
        data =
          id: exercise.id
          exercise_workout_id: exercise.exercise_workout_id
          name: exercise.name
          points: exercise.points
        $('#ex-list').append(Mustache.render($(window.codeworkout.exercise_template).filter('#exercise-template').html(), data))
    $('#ex-list').removeData 'exercises'

init_datepickers = ->
  offerings = $('tr', '#workout-offering-fields tbody')
  for offering in offerings
    do (offering) ->
      init_row_datepickers offering

  extensions = $('tr', '#student-extension-fields tbody')
  for extension in extensions
    do (extension) ->
      init_row_datepickers extension

init_row_datepickers = (row) ->
  opening_datepicker = $('input.opening-datepicker', $(row))
  soft_datepicker = $('input.soft-datepicker', $(row))
  hard_datepicker = $('input.hard-datepicker', $(row))

  if opening_datepicker.val() == '' || !opening_datepicker.data('DateTimePicker').date()?
    opening_datepicker.datetimepicker
      useCurrent: false
      minDate: moment()
  if soft_datepicker.val() == '' || !soft_datepicker.data('DateTimePicker').date()?
    soft_datepicker.datetimepicker
      useCurrent: false
  if hard_datepicker.val() == '' || !hard_datepicker.data('DateTimePicker').date()?
    hard_datepicker.datetimepicker
      useCurrent: false

  # Handle date change events
  opening_datepicker.on 'dp.change', (e) ->
    if e.date?
      soft_datepicker.data('DateTimePicker').minDate e.date
      hard_datepicker.data('DateTimePicker').minDate e.date

  soft_datepicker.on 'dp.change', (e) ->
    if e.date?
      opening_datepicker.data('DateTimePicker').maxDate e.date
      hard_datepicker.data('DateTimePicker').minDate e.date

  hard_datepicker.on 'dp.change', (e) ->
    if e.date?
      soft_datepicker.data('DateTimePicker').maxDate e.date

  # Set existing values, if applicable
  if $('body').is '.workouts.edit'
    if opening_datepicker.data('date')? && opening_datepicker.data('date') != ''
      opening_date = moment.unix(parseInt(opening_datepicker.data('date')))
      if opening_date.isBefore moment()
        opening_datepicker.data('DateTimePicker').minDate opening_date
      else
        opening_datepicker.data('DateTimePicker').minDate moment()
      opening_datepicker.data('DateTimePicker').defaultDate opening_date
    if soft_datepicker.data('DateTimePicker').date()?
      opening_datepicker.data('DateTimePicker').maxDate soft_datepicker.data('DateTimePicker').date()
    else if hard_datepicker.data('DateTimePicker').date()?
      opening_datepicker.data('DateTimePicker').maxDate hard_datepicker.data('DateTimePicker').date()

    if soft_datepicker.data('date')? && soft_datepicker.data('date') != ''
      soft_date = moment.unix(parseInt(soft_datepicker.data('date')))
      soft_datepicker.data('DateTimePicker').defaultDate soft_date
    if opening_datepicker.data('DateTimePicker').date()?
      soft_datepicker.data('DateTimePicker').minDate opening_datepicker.data('DateTimePicker').date()
    if hard_datepicker.data('DateTimePicker').date()?
      soft_datepicker.data('DateTimePicker').maxDate hard_datepicker.data('DateTimePicker').date()

    if hard_datepicker.data('date')? && hard_datepicker.data('date') != ''
      hard_date = moment.unix(parseInt(hard_datepicker.data('date')))
      hard_datepicker.data('DateTimePicker').defaultDate hard_date
    if soft_datepicker.data('DateTimePicker').date()?
      hard_datepicker.data('DateTimePicker').minDate soft_datepicker.data('DateTimePicker').date()
    else if opening_datepicker.data('DateTimePicker').date()?
      hard_datepicker.data('DateTimePicker').minDate opening_datepicker.data('DateTimePicker').date()

get_exercises = ->
  exs = $('#ex-list li')
  exercises = {}
  i = 0
  while i < exs.length
    ex_id = $(exs[i]).data('id')
    ex_points = $(exs[i]).find('.points').val()
    ex_points = '0' if ex_points == ''
    ex_obj = { id: ex_id, points: ex_points }
    position = i + 1
    exercises[position.toString()] = ex_obj
    i++
  return exercises

get_offerings = ->
  offerings = {}
  offering_rows = $('tr', '#workout-offering-fields tbody')
  for offering_row in offering_rows
    do (offering_row) ->
      offering_fields = $('td', $(offering_row))
      offering_id = $('.coff-select', $(offering_fields[0])).val()
      if offering_id != ''
        opening_datepicker = $('.opening-datepicker', $(offering_fields[1])).data('DateTimePicker').date()
        soft_datepicker = $('.soft-datepicker', $(offering_fields[2])).data('DateTimePicker').date()
        hard_datepicker = $('.hard-datepicker', $(offering_fields[3])).data('DateTimePicker').date()

        opening_date = if opening_datepicker? then opening_datepicker.toDate().toString() else null
        soft_deadline = if soft_datepicker? then soft_datepicker.toDate().toString() else null
        hard_deadline = if hard_datepicker? then hard_datepicker.toDate().toString() else null
        published = $('.published', $(offering_fields[4])).is ':checked'

        offering =
          opening_date: opening_date
          soft_deadline: soft_deadline
          hard_deadline: hard_deadline
          published: published
          extensions: []

        offerings[offering_id.toString()] = offering
  return offerings

get_offerings_with_extensions = ->
  offerings = get_offerings()
  extension_rows = $('tr', '#student-extension-fields tbody')
  for extension_row in extension_rows
    do (extension_row) ->
      extension_fields = $('td', $(extension_row))
      student_id = $(extension_row).data 'student-id'
      course_offering_id = $(extension_row).data 'course-offering-id'
      time_limit = $('.time_limit', $(extension_fields[5])).val()
      opening_datepicker = $('.opening-datepicker', $(extension_fields[2])).data('DateTimePicker').date()
      soft_datepicker = $('.soft-datepicker', $(extension_fields[3])).data('DateTimePicker').date()
      hard_datepicker = $('.hard-datepicker', $(extension_fields[4])).data('DateTimePicker').date()

      opening_date = if opening_datepicker? then opening_datepicker.toDate().toString() else null
      soft_deadline = if soft_datepicker? then soft_datepicker.toDate().toString() else null
      hard_deadline = if hard_datepicker? then hard_datepicker.toDate().toString() else null

      extension =
        student_id: student_id
        time_limit: time_limit
        opening_date: opening_date
        soft_deadline: soft_deadline
        hard_deadline: hard_deadline

      offerings[course_offering_id.toString()]['extensions'].push extension

  return offerings

form_alert = (messages) ->
  reset_alert_area()

  alert_list = $('#alerts').find '.alert ul'
  for message in messages
    do (message) ->
      alert_list.append '<li>' + message + '</li>'

  $('#alerts').css 'display', 'block'

reset_alert_area = ->
  $('#alerts').find('.alert').alert 'close'
  alert_box =
    "<div class='alert alert-danger alert-dismissable' role='alert'>" +
      "<button class='close' data-dismiss='alert' aria-label='Close'><i class='fa fa-times'></i></button>" +
      "<ul></ul>" +
    "</div>";
  $('#alerts').append alert_box

check_completeness = ->
  messages = []
  messages.push 'Workout Name cannot be empty.' if $('#wo-name').val() == ''
  messages.push 'Change the name of the workout so you can create a clone with your settings.' if !validate_workout_name()
  messages.push 'Workout must have at least 1 exercise.' if $('#ex-list li').length == 0

  if $('body').hasClass '.workouts.new'
    course_offering_selects = $('#workout-offering-fields').find '.coff-select'
    coff_errs = 0
    for select in course_offering_selects
      do (select) ->
        coff_errs = coff_errs + 1 if $(select).val() == ''
    messages.push 'You must select a Course Offering for this Workout. (x' + coff_errs + ')' if coff_errs > 0

  return messages

handle_submit = ->
  messages = check_completeness()
  if messages.length != 0
    form_alert messages
    return

  name = $('#wo-name').val()
  description = $('#description').val()
  time_limit = $('#time-limit').val()
  policy_id = $('#policy-select').val()
  is_public = $('#is-public').is ':checked'
  removed_exercises = $('#ex-list').data 'removed-exercises'
  exercises = get_exercises()
  course_offerings = get_offerings_with_extensions()
  fd = new FormData
  fd.append 'name', name
  fd.append 'description', description
  fd.append 'time_limit', time_limit
  fd.append 'policy_id', policy_id
  fd.append 'exercises', JSON.stringify exercises
  fd.append 'course_offerings', JSON.stringify course_offerings
  fd.append 'removed_exercises', JSON.stringify window.codeworkout.removed_exercises
  fd.append 'removed_offerings', JSON.stringify window.codeworkout.removed_offerings
  fd.append 'removed_extensions', JSON.stringify window.codeworkout.removed_extensions
  fd.append 'is_public', is_public
  # Tells the server whether this form is being submitted through LTI or not.
  # The window.codeworkout namespace was declared in the workouts/_form partial.
  fd.append 'lti_launch', window.codeworkout.lti_launch if window.codeworkout.lti_launch != ''

  if $('body').is '.workouts.new'
    url = '/gym/workouts'
    type = 'post'
  else if $('body').is '.workouts.edit'
    can_update = $('#workout-offering-fields').data 'can-update'
    url = if can_update == true then '/gym/workouts/' + $('h1').data 'id' else '/gym/workouts'
    type = if can_update == true then 'patch' else 'post'

  $.ajax
    url: url
    type: type
    data: fd
    processData: false
    contentType: false
    success: (data) ->
      window.location.href = data['url']
