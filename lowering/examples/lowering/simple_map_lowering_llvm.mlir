module {
  llvm.func @malloc(!llvm.i64) -> !llvm<"i8*">
  llvm.func @riseFun() -> !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }"> {
    %0 = llvm.mlir.constant(5.000000e+00 : f32) : !llvm.float
    %1 = llvm.mlir.constant(0 : index) : !llvm.i64
    %2 = llvm.mlir.constant(4 : index) : !llvm.i64
    %3 = llvm.mlir.constant(1 : index) : !llvm.i64
    %4 = llvm.mlir.constant(4 : index) : !llvm.i64
    %5 = llvm.mlir.null : !llvm<"float*">
    %6 = llvm.mlir.constant(1 : index) : !llvm.i64
    %7 = llvm.getelementptr %5[%6] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    %8 = llvm.ptrtoint %7 : !llvm<"float*"> to !llvm.i64
    %9 = llvm.mul %4, %8 : !llvm.i64
    %10 = llvm.call @malloc(%9) : (!llvm.i64) -> !llvm<"i8*">
    %11 = llvm.bitcast %10 : !llvm<"i8*"> to !llvm<"float*">
    %12 = llvm.mlir.undef : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %13 = llvm.insertvalue %11, %12[0] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %14 = llvm.insertvalue %11, %13[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %15 = llvm.mlir.constant(0 : index) : !llvm.i64
    %16 = llvm.insertvalue %15, %14[2] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %17 = llvm.mlir.constant(1 : index) : !llvm.i64
    %18 = llvm.insertvalue %4, %16[3, 0] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %19 = llvm.insertvalue %17, %18[4, 0] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    llvm.br ^bb1(%1 : !llvm.i64)
  ^bb1(%20: !llvm.i64):	// 2 preds: ^bb0, ^bb2
    %21 = llvm.icmp "slt" %20, %2 : !llvm.i64
    llvm.cond_br %21, ^bb2, ^bb3
  ^bb2:	// pred: ^bb1
    %22 = llvm.extractvalue %19[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %23 = llvm.mlir.constant(0 : index) : !llvm.i64
    %24 = llvm.mlir.constant(1 : index) : !llvm.i64
    %25 = llvm.mul %20, %24 : !llvm.i64
    %26 = llvm.add %23, %25 : !llvm.i64
    %27 = llvm.getelementptr %22[%26] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    llvm.store %0, %27 : !llvm<"float*">
    %28 = llvm.add %20, %3 : !llvm.i64
    llvm.br ^bb1(%28 : !llvm.i64)
  ^bb3:	// pred: ^bb1
    llvm.br ^bb4(%1 : !llvm.i64)
  ^bb4(%29: !llvm.i64):	// 2 preds: ^bb3, ^bb5
    %30 = llvm.icmp "slt" %29, %2 : !llvm.i64
    llvm.cond_br %30, ^bb5, ^bb6
  ^bb5:	// pred: ^bb4
    %31 = llvm.extractvalue %19[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %32 = llvm.mlir.constant(0 : index) : !llvm.i64
    %33 = llvm.mlir.constant(1 : index) : !llvm.i64
    %34 = llvm.mul %29, %33 : !llvm.i64
    %35 = llvm.add %32, %34 : !llvm.i64
    %36 = llvm.getelementptr %31[%35] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    %37 = llvm.load %36 : !llvm<"float*">
    %38 = llvm.fadd %37, %37 : !llvm.float
    %39 = llvm.extractvalue %19[1] : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %40 = llvm.mlir.constant(0 : index) : !llvm.i64
    %41 = llvm.mlir.constant(1 : index) : !llvm.i64
    %42 = llvm.mul %29, %41 : !llvm.i64
    %43 = llvm.add %40, %42 : !llvm.i64
    %44 = llvm.getelementptr %39[%43] : (!llvm<"float*">, !llvm.i64) -> !llvm<"float*">
    llvm.store %38, %44 : !llvm<"float*">
    %45 = llvm.add %29, %3 : !llvm.i64
    llvm.br ^bb4(%45 : !llvm.i64)
  ^bb6:	// pred: ^bb4
    llvm.return %19 : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
  }
  llvm.func @print_memref_f32(!llvm.i64, !llvm<"i8*">)
  llvm.func @simple_map_example() {
    %0 = llvm.call @riseFun() : () -> !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }">
    %1 = llvm.mlir.constant(1 : index) : !llvm.i64
    %2 = llvm.alloca %1 x !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }"> : (!llvm.i64) -> !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }*">
    llvm.store %0, %2 : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }*">
    %3 = llvm.bitcast %2 : !llvm<"{ float*, float*, i64, [1 x i64], [1 x i64] }*"> to !llvm<"i8*">
    %4 = llvm.mlir.constant(1 : i64) : !llvm.i64
    %5 = llvm.mlir.undef : !llvm<"{ i64, i8* }">
    %6 = llvm.insertvalue %4, %5[0] : !llvm<"{ i64, i8* }">
    %7 = llvm.insertvalue %3, %6[1] : !llvm<"{ i64, i8* }">
    %8 = llvm.extractvalue %7[0] : !llvm<"{ i64, i8* }">
    %9 = llvm.extractvalue %7[1] : !llvm<"{ i64, i8* }">
    llvm.call @print_memref_f32(%8, %9) : (!llvm.i64, !llvm<"i8*">) -> ()
    llvm.return
  }
}
