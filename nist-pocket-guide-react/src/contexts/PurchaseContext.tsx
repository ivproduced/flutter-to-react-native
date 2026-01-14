// src/contexts/PurchaseContext.tsx

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import localforage from 'localforage';

interface PurchaseContextType {
  isPro: boolean;
  isLoading: boolean;
  purchasePro: () => Promise<boolean>;
  restorePurchases: () => Promise<boolean>;
}

const PurchaseContext = createContext<PurchaseContextType | undefined>(undefined);

export const usePurchase = () => {
  const context = useContext(PurchaseContext);
  if (!context) {
    throw new Error('usePurchase must be used within PurchaseProvider');
  }
  return context;
};

interface PurchaseProviderProps {
  children: ReactNode;
}

export const PurchaseProvider: React.FC<PurchaseProviderProps> = ({ children }) => {
  const [isPro, setIsPro] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const initialize = async () => {
      try {
        const proStatus = await localforage.getItem<boolean>('is_pro');
        setIsPro(proStatus ?? false);
      } catch (error) {
        console.error('Error loading purchase status:', error);
      } finally {
        setIsLoading(false);
      }
    };

    initialize();
  }, []);

  const purchasePro = async (): Promise<boolean> => {
    // TODO: Implement web payment integration (Stripe, PayPal, etc.)
    // For now, this is a placeholder that simulates purchase
    try {
      setIsLoading(true);
      // Simulate payment processing
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      await localforage.setItem('is_pro', true);
      setIsPro(true);
      setIsLoading(false);
      return true;
    } catch (error) {
      console.error('Error purchasing Pro:', error);
      setIsLoading(false);
      return false;
    }
  };

  const restorePurchases = async (): Promise<boolean> => {
    // TODO: Implement restore purchases logic with backend verification
    try {
      setIsLoading(true);
      const proStatus = await localforage.getItem<boolean>('is_pro');
      setIsPro(proStatus ?? false);
      setIsLoading(false);
      return true;
    } catch (error) {
      console.error('Error restoring purchases:', error);
      setIsLoading(false);
      return false;
    }
  };

  return (
    <PurchaseContext.Provider
      value={{
        isPro,
        isLoading,
        purchasePro,
        restorePurchases,
      }}
    >
      {children}
    </PurchaseContext.Provider>
  );
};
