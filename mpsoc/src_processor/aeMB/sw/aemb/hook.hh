#ifdef __cplusplus
extern "C" {
#endif
	void _program_init();
    void _program_clean();
    
    // newlib locks
    void __malloc_lock(struct _reent *reent);
    void __malloc_unlock(struct _reent *reent);

  
   #ifdef __cplusplus
}
#endif 
 
