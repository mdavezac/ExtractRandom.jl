module ExtractRandomTest
using ExtractRandom
using Base.Test

@testset "Poisson" begin
    # Sanguetti, et al, PRX 4, 031056 (2014), just because
    @test poisson_min_entropy(big(1.5e4), basis=2) ≈ 8.2620935198439106576388550
    @test poisson_min_entropy(big(410), basis=2) ≈ 5.66578134513010429986151
end

@testset "2 universal hashing" begin
    @testset "With bits" begin
        a = convert(BitMatrix, [false true; true true; false false])
        v = convert(BitVector, [false, true])
        @test two_universal(a, v) == [true, true, false]

        a = [true true true; true false true; false false true]
        v = [false, true, true]
        @test two_universal(a, v) == [false, true, true]
    end

    @testset "xor bits of an integer" begin
        Nbits = sizeof(typeof(1)) - 1
        @test ExtractRandom.xorbits(0) == false
        for i in 0:Nbits
            @test ExtractRandom.xorbits(1 << i) == true
            for j in (i + 1):Nbits
                @test ExtractRandom.xorbits((1 << j) | (1 << i)) == false
                for k in (j + 1):Nbits
                    @test ExtractRandom.xorbits((1 << j) | (1 << i) | (1 << k)) == true
                end
            end
        end
    end

    @testset "bit and integer representation" begin

        @test bit_representation([1]) == BitArray(vcat(zeros(Integer, 63), [1]))
        @test bit_representation([3]) == BitArray(vcat(zeros(Int64, 62), [1, 1]))
        @test bit_representation([6]) == BitArray(vcat(zeros(Int64, 61), [1, 1, 0]))
        expected = BitArray(vcat(zeros(Int64, 61), [1, 1, 0], zeros(Integer, 63), [1]))
        @test bit_representation([6, 1]) == expected

        @test integer_representation(Int64, bit_representation([1])) == [1]
        @test integer_representation(Int64, bit_representation([2])) == [2]
        @test integer_representation(Int64, bit_representation([3])) == [3]
        @test integer_representation(Int64, bit_representation([-3])) == [-3]

        a = rand(Int64, (rand(1:100, )))
        @test integer_representation(Int64, bit_representation(a)) == a
    end

    @testset "With bytes" begin
        @testset "Just one block (no modulo)" begin
            a = UInt8[1 2; 3 4]
            v = UInt8[1, 1]
            @test two_universal(a, v) == [(UInt8(1) << 7 | (UInt8(1) << 6))]

            const xorbits = ExtractRandom.xorbits
            a = UInt8[1 2; 3 4]
            v = UInt8[1, 3]
            expected = (xorbits((1 & 1) | (2 & 3)) << 7 | (xorbits((1 & 3) | (3 & 4)) << 6))
            @test two_universal(a, v) == [expected]
        end

        @testset "vs bit arrays" begin
            a = rand(Int8, (rand(1:100, 2)...))
            v = rand(Int8, 3size(a, 2))
            abool = bit_representation(a)
            abool = reshape(abool, (8sizeof(eltype(a)), size(a)...))
            abool = permutedims(abool, [2, 1, 3:ndims(abool)...])
            abool = reshape(abool, (size(a, 1), 8sizeof(eltype(a)) * size(a, 2)))

            # makes sure the matrix is represented correctly
            for i in 1:size(a, 1)
                @test integer_representation(Int8, abool[i, :]) == a[i, :]
            end

            vbool = bit_representation(v)

            x = two_universal(a, v)
            xbool = two_universal(abool, vbool)
            @test bit_representation(x)[1:length(xbool)] == xbool
        end
    end
end
end