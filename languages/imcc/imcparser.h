typedef union {
    int t;
    char * s;
    SymReg * sr;
    Instruction *i;
} YYSTYPE;
#define	CALL	258
#define	GOTO	259
#define	ARG	260
#define	PRINT	261
#define	IF	262
#define	UNLESS	263
#define	NEW	264
#define	END	265
#define	SAVEALL	266
#define	RESTOREALL	267
#define	SUB	268
#define	NAMESPACE	269
#define	CLASS	270
#define	ENDCLASS	271
#define	SYM	272
#define	LOCAL	273
#define	PARAM	274
#define	INC	275
#define	DEC	276
#define	SHIFT_LEFT	277
#define	SHIFT_RIGHT	278
#define	INTV	279
#define	FLOATV	280
#define	STRINGV	281
#define	DEFINED	282
#define	LOG_XOR	283
#define	RELOP_EQ	284
#define	RELOP_NE	285
#define	RELOP_GT	286
#define	RELOP_GTE	287
#define	RELOP_LT	288
#define	RELOP_LTE	289
#define	GLOBAL	290
#define	ADDR	291
#define	CLONE	292
#define	RESULT	293
#define	RETURN	294
#define	POW	295
#define	SHIFT_RIGHT_U	296
#define	LOG_AND	297
#define	LOG_OR	298
#define	COMMA	299
#define	ESUB	300
#define	LABEL	301
#define	EMIT	302
#define	EOM	303
#define	IREG	304
#define	NREG	305
#define	SREG	306
#define	PREG	307
#define	IDENTIFIER	308
#define	STRINGC	309
#define	INTC	310
#define	FLOATC	311
#define	REG	312
#define	MACRO	313
#define	PARROT_OP	314
#define	VAR	315


extern YYSTYPE yylval;
