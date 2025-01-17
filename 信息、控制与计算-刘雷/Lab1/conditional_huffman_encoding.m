function conditional_huffman_encoding()
    clc; clear; close all;
    space = 1:4;
    px1 = [1/2 1/4 1/8 1/8]; 
    P = [1/2 1/4 1/8 1/8; 
         1/4 1/8 1/8 1/2; 
         1/8 1/8 1/2 1/4; 
         1/8 1/2 1/4 1/8];
    n = 10; 

    % Generate Markov chain
    x = Markov_chain(space, px1, P, n); 
    disp('Generated Markov chain:');
    disp(x);

    % Encode using conditional Huffman coding
    [cx, R, Hx, z] = Conditional_Huffman_Encoding(x, space, px1, P); 
    disp('Stationary distribution (z):');
    disp(z);
    fprintf('Entropy rate (Hx): %.4f\n', Hx);
    fprintf('Encoding rate (R): %.4f bits/symbol\n', R);

    % Decode the encoded sequence
    x_dec = Conditional_Huffman_Decoding(cx, px1, P); 
    disp('Decoded sequence:');
    disp(x_dec);

    % Check decoding correctness
    error = sum(abs(x_dec - x));
    if error == 0
        disp('Decoding successful: no errors detected.');
    else
        fprintf('Decoding error: %d discrepancies found.\n', error);
    end
end

%% Source generation function
function [x] = Markov_chain(space, px1, P, n)
    % Generate Markov chain of length n
    x = zeros(1, n);

    % Initial state sampling
    p = px1;                  
    cdf_px1 = cumsum(p);       
    r = rand;
    idx_first = find(r <= cdf_px1, 1, 'first');
    x(1) = space(idx_first);   

    % Subsequent states sampling
    for i = 2:n
        prev_state = x(i-1);
        row_idx = find(space == prev_state, 1, 'first');
        p_current = P(row_idx, :);
        cdf_p_current = cumsum(p_current);
        r = rand;
        idx_i = find(r <= cdf_p_current, 1, 'first');
        x(i) = space(idx_i);
    end
end

%% Encoding process function
function [cx, R, Hx, z] = Conditional_Huffman_Encoding(x, space, px1, P)
    % Conditional Huffman encoding
    N = length(x);          
    M = length(space);      

    % Compute stationary distribution
    A = [P' - eye(M); ones(1,M)];
    b = [zeros(M,1); 1];
    z_ = A\b;              
    z = z_.'/sum(z_);      

    % Compute entropy rate
    Hi = zeros(1, M);       
    for i = 1:M
        p_i_nonzero = P(i, P(i, :) > 0);
        Hi(i) = -sum(p_i_nonzero .* log2(p_i_nonzero));
    end
    Hx = sum(z .* Hi);

    % Encoding
    cx = cell(1, N);     
    totalBits = 0;      
    
    % Encode x(1) using px1
    [dict_init, ~] = huffmandict(space, px1);
    codeword = dict_init{x(1), 2};
    cx{1} = codeword;
    totalBits = totalBits + length(codeword);
    
    % Encode x(2) ~ x(N)
    for i = 2:N
        prev_symb = x(i-1);
        row_idx = find(space == prev_symb, 1, 'first');
        p_cond = P(row_idx, :);
        [dict_curr, ~] = huffmandict(space, p_cond);
        codeword = dict_curr{x(i), 2};
        cx{i} = codeword;
        totalBits = totalBits + length(codeword);
    end
    
    % Compute actual rate
    R = totalBits / N;
end

%% Decoding process function
function [x_dec] = Conditional_Huffman_Decoding(cx, px1, P)
    % Initialize variables
    N = length(cx);
    M = length(px1);
    space = 1:M;
    x_dec = zeros(1, N);

    % Decode the first symbol using the initial probability distribution
    [dict_init, ~] = huffmandict(space, px1);
    codeword_1 = cx{1};
    for k = 1:size(dict_init, 1)
        if isequal(dict_init{k, 2}, codeword_1)
            x_dec(1) = dict_init{k, 1};
            break;
        end
    end

    % Decode the remaining symbols based on conditional probabilities
    for i = 2:N
        prev_symb = x_dec(i-1); % Previous decoded symbol
        row_idx = find(space == prev_symb, 1); % Find corresponding row in P
        p_cond = P(row_idx, :); % Conditional probabilities
        [dict_curr, ~] = huffmandict(space, p_cond);
        codeword_i = cx{i};
        for k = 1:size(dict_curr, 1)
            if isequal(dict_curr{k, 2}, codeword_i)
                x_dec(i) = dict_curr{k, 1};
                break;
            end
        end
    end
end
