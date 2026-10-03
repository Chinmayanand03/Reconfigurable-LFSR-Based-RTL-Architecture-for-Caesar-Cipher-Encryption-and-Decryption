package crypto_reference_pkg; 
 
    function automatic [7:0] caesar_encrypt_ref( 
        input logic [7:0] data_in, 
        input logic [4:0] shift_key 
    ); 
        integer idx; 
        integer shifted; 
        begin 
            caesar_encrypt_ref = data_in; 
            if ((data_in >= 8'h41) && (data_in <= 8'h5A)) begin 
                idx = data_in - 8'h41; 
                shifted = idx + shift_key; 
                while (shifted >= 26) 
                    shifted = shifted - 26; 
                caesar_encrypt_ref = 8'h41 + shifted; 
            end else if ((data_in >= 8'h61) && (data_in <= 8'h7A)) begin 
                idx = data_in - 8'h61; 
                shifted = idx + shift_key; 
                while (shifted >= 26) 
                    shifted = shifted - 26; 
                caesar_encrypt_ref = 8'h61 + shifted; 
            end 
        end 
    endfunction 
 
    function automatic [7:0] caesar_decrypt_ref( 
        input logic [7:0] data_in, 
        input logic [4:0] shift_key 
    ); 
        integer idx; 
        integer shifted; 
        begin 
            caesar_decrypt_ref = data_in; 
            if ((data_in >= 8'h41) && (data_in <= 8'h5A)) begin 
                idx = data_in - 8'h41; 
                shifted = idx - shift_key; 
                while (shifted < 0) 
                    shifted = shifted + 26; 
                caesar_decrypt_ref = 8'h41 + shifted; 
            end else if ((data_in >= 8'h61) && (data_in <= 8'h7A)) begin 
                idx = data_in - 8'h61; 
                shifted = idx - shift_key; 
                while (shifted < 0) 
                    shifted = shifted + 26; 
                caesar_decrypt_ref = 8'h61 + shifted; 
            end 
        end 
    endfunction 
 
    function automatic [11:0] lfsr_next_ref(input logic [11:0] state); 
        logic feedback; 
        begin 
            feedback = state[11] ^ state[5] ^ state[3] ^ state[0]; 
            lfsr_next_ref = {state[10:0], feedback}; 
        end 
    endfunction 
 
    function automatic [4:0] effective_key_ref( 
        input logic [11:0] lfsr_state, 
        input logic [4:0] configured_shift 
    ); 
        integer key; 
        begin 
            key = (lfsr_state % 26) + configured_shift; 
            effective_key_ref = key % 26; 
        end 
    endfunction 
 
endpackage 
