%lb = constant 0 : index
%ub = constant 4 : index //half open index, so 4 iterations
%step = constant 1 : index
%result = loop.parallel (%iv) = (%lb) to (%ub) step (%step) {
    %zero = constant 0.0 : f32
    loop.reduce(%zero) {
      ^bb0(%lhs : f32, %rhs: f32):
        %res = addf %lhs, %rhs : f32
        loop.reduce.return %res : f32
    } : f32
} :f32
