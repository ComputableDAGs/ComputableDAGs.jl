ph_out = ($(Expr(:opaque_closure,:(() -> begin
    begin
        local ph_out, var"::", var"ParticleValueSP{ParticleStateful{Outgoing, Photon, SFourMomentum}, PolarizationX, ComplexF64}"
    end
    ph_out = ParticleValueSP(
        ParticleStateful{Outgoing,Photon,SFourMomentum}(momentum(input, Outgoing(), Photon(), Val(1))),
        0.0im,
        PolX(),
    )
    return ph_out
end))))()
el_in = (
    $(Expr(
        :opaque_closure,
        :(
            () -> begin
                begin
                    local el_in, var"::", var"ParticleValueSP{ParticleStateful{Incoming, Electron, SFourMomentum}, SpinUp, ComplexF64}"
                end
                el_in = ParticleValueSP(
                    ParticleStateful{Incoming,Electron,SFourMomentum}(momentum(input, Incoming(), Electron(), Val(1))),
                    0.0im,
                    SpinUp(),
                )
                return el_in
            end
        ),
    ))
)()
ph_in = (
    $(Expr(
        :opaque_closure,
        :(
            () -> begin
                begin
                    local ph_in, var"::", var"ParticleValueSP{ParticleStateful{Incoming, Photon, SFourMomentum}, PolarizationX, ComplexF64}"
                end
                ph_in = ParticleValueSP(
                    ParticleStateful{Incoming,Photon,SFourMomentum}(momentum(input, Incoming(), Photon(), Val(1))),
                    0.0im,
                    PolX(),
                )
                return ph_in
            end
        ),
    ))
)()
el_out = (
    $(Expr(
        :opaque_closure,
        :(
            () -> begin
                begin
                    local el_out, var"::", var"ParticleValueSP{ParticleStateful{Outgoing, Electron, SFourMomentum}, SpinUp, ComplexF64}"
                end
                el_out = ParticleValueSP(
                    ParticleStateful{Outgoing,Electron,SFourMomentum}(momentum(input, Outgoing(), Electron(), Val(1))),
                    0.0im,
                    SpinUp(),
                )
                return el_out
            end
        ),
    ))
)()