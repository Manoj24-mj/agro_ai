import streamlit as st

def main():
    st.set_page_config(page_title="Password Validator", page_icon="🔒")
    
    st.title("Secure Password Input")
    st.markdown("Please enter a password that is exactly 8 characters long.")

    # Initialize state for password visibility
    if "show_password" not in st.session_state:
        st.session_state.show_password = False

    # Function to toggle visibility
    def toggle_visibility():
        st.session_state.show_password = not st.session_state.show_password

    # Container for password input and toggle button
    col1, col2 = st.columns([4, 1])
    
    with col2:
        # Align button to the bottom to match text input
        st.write("") 
        st.write("")
        st.button(
            "🐵" if st.session_state.show_password else "🙈", 
            on_click=toggle_visibility,
            help="Show/Hide Password"
        )

    with col1:
        # Streamlit's max_chars strictly limits the input and prevents further typing!
        password = st.text_input(
            "Password", 
            type="default" if st.session_state.show_password else "password",
            max_chars=8,
            key="password_field"
        )

    # Real-time character counter
    char_count = len(password)
    
    # CSS to style the counter based on length (green if 8, else default text color)
    counter_color = "green" if char_count == 8 else "gray"
    st.markdown(
        f'<p style="color: {counter_color}; font-weight: bold;">{char_count}/8</p>', 
        unsafe_allow_html=True
    )

    # Visual validation indicator
    if char_count == 8:
        st.success("✅ Password length is perfectly 8 characters!")
    elif char_count > 0:
        st.error(f"❌ Need exactly 8 characters (Currently {char_count})")
    else:
        st.info("ℹ️ Enter your password above.")

if __name__ == "__main__":
    main()
