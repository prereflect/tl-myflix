require 'spec_helper'

feature 'User Sign In' do
  given(:toby) { Fabricate(:user) }

  background do
    visit root_path
    click_link 'Sign In'
  end

  scenario 'with correct credentials' do
    fill_in 'email', with: toby.email
    fill_in 'password', with: toby.password
    click_button 'Sign in'
    expect(page).to have_content 'You are now signed in'
  end

  scenario 'with incorrect credentials' do
    fill_in 'email', with: toby.email
    fill_in 'password', with: toby.password + 'wrong'
    click_button 'Sign in'
    expect(page).to have_content 'Invalid email or password'
  end
end