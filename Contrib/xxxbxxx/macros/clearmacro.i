%MACRO fill32  colour
        LDI     colour
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        POKE    vbase
        INC     vbase
        LD      vbase
        BNE     skip
        
        LD      vbase+1
        ADDI    0x01
        ST      vbase+1
skip    LDI     0x00
%ENDM
